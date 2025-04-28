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
                // Cast x and y to u16 for calculations that expect u16
                const new_x: u16 = @intCast(x);
                const new_y: u16 = @intCast(y);
                const map_x: u16 = @as(u16, new_x / 8); // Cast x to u16
                const map_y: u16 = @as(u16, new_y / 8); // Cast y to u16
                const tile_index_address = tile_map_base + map_y * 32 + map_x;

                // Read tile index from the background map
                const tile_index = cpu.read_memory(tile_index_address);

                // Compute tile data address
                const tile_address = tile_data_base + @as(u16, tile_index) * 16;

                // Each tile row is 2 bytes
                const tile_row = @as(u16, (new_y % 8)) * 2;
                const byte1 = cpu.read_memory(tile_address + tile_row);
                const byte2 = cpu.read_memory(tile_address + tile_row + 1);

                const bit = 7 - (new_x % 8);
                const color_low = @as(u8, byte1 >> @intCast(bit)) & 0x1;
                const color_high = @as(u8, byte2 >> @intCast(bit)) & 0x1;
                const color = (color_high << 1) | color_low;

                // Write the pixel color into the framebuffer
                self.framebuffer[new_y * SCREEN_WIDTH + new_x] = color;
            }
        }
    }
};
