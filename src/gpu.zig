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
        // Hardcoded base addresses (we will read LCDC later to decide dynamically)
        const tile_map_base: u16 = 0x9800;
        const tile_data_base: u16 = 0x8000;

        for (0..SCREEN_HEIGHT) |y| {
            for (0..SCREEN_WIDTH) |x| {
                const map_x = x / 8;
                const map_y = y / 8;
                const tile_index_address = tile_map_base + @as(u16, map_y) * 32 + @as(u16, map_x);

                // Read tile index from the background map
                const tile_index = cpu.read_memory(tile_index_address);

                // Compute tile data address
                const tile_address = tile_data_base + @as(u16, tile_index) * 16;

                // Each tile row is 2 bytes
                const tile_row = @as(u16, (y % 8)) * 2;
                const byte1 = cpu.read_memory(tile_address + tile_row);
                const byte2 = cpu.read_memory(tile_address + tile_row + 1);

                const bit = 7 - (x % 8);
                const color_low = (byte1 >> bit) & 0x1;
                const color_high = (byte2 >> bit) & 0x1;
                const color = (color_high << 1) | color_low;

                // Write the pixel color into the framebuffer
                self.framebuffer[y * SCREEN_WIDTH + x] = color;
            }
        }
    }
};
