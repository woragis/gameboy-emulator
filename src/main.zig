const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;
const SdlContext = @import("sdl.zig").SdlContext;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Print current working directory
    const path_buf = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(path_buf);
    try stdout.print("Current directory: {s}\n", .{path_buf});

    try stdout.print("Enter path to .gb file: ", .{});
    var input_buffer: [256]u8 = undefined;
    const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
    const path = std.mem.trimRight(u8, input orelse "tetris.gb", "\r\n");

    try stdout.print("Loading ROM from path: {s}\n", .{path});

    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const rom = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(rom);
    try stdout.print("Loaded ROM successfully! Size: {} bytes\n", .{rom.len});

    // Initialize CPU and SDL
    var cpu = Cpu.init(); // or use ?Cpu and unwrap if Cpu.init() returns optional
    var sdl = try SdlContext.init();
    defer sdl.deinit();

    // Load the ROM into the CPU
    cpu.load_rom(rom);

    // Main loop to run the emulator
    try stdout.print("Starting emulator...\n", .{});
    while (true) {
        cpu.run();
        cpu.gpu.render_frame(&cpu);
        sdl.draw_frame(&cpu.gpu.framebuffer);
        std.time.sleep(16 * std.time.ns_per_s / 1000);
    }
}
