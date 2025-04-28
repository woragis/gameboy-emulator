const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const gpu = @import("gpu.zig");

pub const SdlContext = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    texture: *sdl.SDL_Texture,

    pub fn init() !SdlContext {
        if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0)
            return error.SdlInitFailed;

        const window = sdl.SDL_CreateWindow(
            "GameBoy Emulator",
            sdl.SDL_WINDOWPOS_CENTERED,
            sdl.SDL_WINDOWPOS_CENTERED,
            gpu.SCREEN_WIDTH * 2, // Scale 2x
            gpu.SCREEN_HEIGHT * 2,
            0,
        ) orelse return error.WindowCreationFailed;

        const renderer = sdl.SDL_CreateRenderer(window, -1, 0) orelse return error.RendererCreationFailed;

        const texture = sdl.SDL_CreateTexture(
            renderer,
            sdl.SDL_PIXELFORMAT_RGB24,
            sdl.SDL_TEXTUREACCESS_STREAMING,
            gpu.SCREEN_WIDTH,
            gpu.SCREEN_HEIGHT,
        ) orelse return error.TextureCreationFailed;

        return SdlContext{
            .window = window,
            .renderer = renderer,
            .texture = texture,
        };
    }

    pub fn deinit(self: *SdlContext) void {
        sdl.SDL_DestroyTexture(self.texture);
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_Quit();
    }

    pub fn draw_frame(self: *SdlContext, framebuffer: []const u8) void {
        const pixels_ptr: [*c]?*anyopaque = null;
        // const pitch_ptr: [*c]?*c_int = null;
        var pitch: c_int = 0;
        _ = sdl.SDL_LockTexture(self.texture, null, &pixels_ptr.*, &pitch);

        if (pixels_ptr) |pixels| {
            var dst = pixels;
            for (0..gpu.SCREEN_WIDTH * gpu.SCREEN_HEIGHT) |i| {
                const color = framebuffer[i];
                // Map GameBoy colors 0..3 to real RGB colors
                const shade: u8 = switch (color) {
                    0 => 0xFF, // White
                    1 => 0xAA, // Light Gray
                    2 => 0x55, // Dark Gray
                    3 => 0x00, // Black
                    else => 0xFF,
                };
                dst.* = shade;
                dst += 1;
                dst.* = shade;
                dst += 1;
                dst.* = shade;
                dst += 1;
            }
            sdl.SDL_UnlockTexture(self.texture);
        }

        _ = sdl.SDL_RenderClear(self.renderer);
        _ = sdl.SDL_RenderCopy(self.renderer, self.texture, null, null);
        sdl.SDL_RenderPresent(self.renderer);
    }
};
