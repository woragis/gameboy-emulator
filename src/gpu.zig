const Cpu = @import("cpu.zig").Cpu;

pub const SCREEN_WIDTH = 160;
pub const SCREEN_HEIGHT = 144;

pub const Gpu = struct {
    framebuffer: [SCREEN_WIDTH * SCREEN_HEIGHT]u8,

    pub fn init() Gpu {
        return Gpu{
            .framebuffer = [_]u8{0} ** (SCREEN_WIDTH * SCREEN_HEIGHT),
        };
    }

    pub fn render_frame(self: *Gpu, cpu: *Cpu) void {
        // Example base addresses (hardcoded for now, read LCDC for real addresses)
        const tile_map_base: u16 = 0x9800;
        const tile_data_base: u16 = 0x8000;

        for (0..SCREEN_HEIGHT) |y| {
            for (0..SCREEN_WIDTH) |x| {
                const map_x = x / 8;
                const map_y = y / 8;
                const tile_index_address = tile_map_base + map_y * 32 + map_x;
                const tile_index = self.read_memory(tile_index_address);

                const tile_address = tile_data_base + tile_index * 16;

                const tile_row = (y % 8) * 2; // Each row is 2 bytes
                const byte1 = self.read_memory(tile_address + tile_row);
                const byte2 = self.read_memory(tile_address + tile_row + 1);

                const bit = 7 - (x % 8);
                const color_low = (byte1 >> bit) & 0x1;
                const color_high = (byte2 >> bit) & 0x1;
                const color = (color_high << 1) | color_low;

                self.framebuffer[y * SCREEN_WIDTH + x] = color;
            }
        }
    }
};
