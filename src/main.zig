const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;
const SdlContext = @import("sdl.zig").SdlContext;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    // const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try stdout.print("Enter path to .gb file: ", .{});

    // var input_buffer: [256]u8 = undefined;
    // const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
    // const path = std.mem.trimRight(u8, input orelse "tetris.gb", "\r\n");
    const path = std.mem.trimRight(u8, "tetris.gb", "\r\n");

    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const rom = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // Read up to 10MB
    defer allocator.free(rom);

    var cpu = Cpu.init();
    var sdl = try SdlContext.init();
    defer sdl.deinit();
    cpu.load_rom(rom);

    try stdout.print("Loaded ROM successfully!\n", .{});

    while (true) {
        cpu.run();
        cpu.gpu.render_frame(&cpu);
        sdl.draw_frame(&cpu.gpu.framebuffer);
        std.time.sleep(16 * std.time.ns_per_s / 1000); // 60 FPS
    }
    try stdout.print("CPU execution finished.\n", .{});
}
