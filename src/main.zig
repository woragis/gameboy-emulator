const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try stdout.print("Enter path to .gb file: ", .{});

    var input_buffer: [256]u8 = undefined;
    const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
    const path = std.mem.trimRight(u8, input orelse "", "\r\n");

    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const rom = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // Read up to 10MB
    defer allocator.free(rom);

    var cpu = Cpu.init();
    cpu.load_rom(rom);

    try stdout.print("Loaded ROM successfully!\n", .{});

    cpu.run();
    try stdout.print("CPU execution finished.\n", .{});
}
