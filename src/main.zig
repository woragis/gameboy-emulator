const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;
const SdlContext = @import("sdl.zig").SdlContext;

pub fn main() !c_int {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Get current directory as a string
    const path_buf = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(path_buf);
    try stdout.print("Current directory: {s}\n", .{path_buf});

    try stdout.print("Enter path to .gb file: ", .{});

    // Reading user input for the path to the .gb file
    var input_buffer: [256]u8 = undefined;
    const input = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n');
    const path = std.mem.trimRight(u8, input orelse "tetris.gb", "\r\n");

    // Debugging file path
    try stdout.print("Loading ROM from path: {}\n", .{path});

    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    // Read the ROM file, with a maximum size of 10MB
    const rom = try file.readToEndAlloc(allocator, 10 * 1024 * 1024); // Read up to 10MB
    defer allocator.free(rom);

    try stdout.print("Loaded ROM successfully! Size: {} bytes\n", .{rom.len});

    // Initialize the CPU and SDL context
    var cpu = Cpu.init();
    var sdl: ?SdlContext = try SdlContext.init();
    defer sdl.deinit();

    // Ensure both CPU and SDL are properly initialized
    if (cpu == null) {
        try stdout.print("CPU initialization failed\n", .{});
        return 1;
    }
    if (sdl == null) {
        try stdout.print("SDL initialization failed\n", .{});
        return 2;
    }

    // Load the ROM into the CPU
    cpu.load_rom(rom);

    // Main loop to run the emulator
    try stdout.print("Starting emulator...\n", .{});
    while (true) {
        // Run the CPU cycle
        cpu.run();

        // Render the frame using the GPU in the CPU
        cpu.gpu.render_frame(&cpu);

        // Draw the frame using SDL
        sdl.draw_frame(&cpu.gpu.framebuffer);

        // Sleep for 16ms for ~60 FPS
        std.time.sleep(16 * std.time.ns_per_s / 1000);
    }

    try stdout.print("CPU execution finished.\n", .{});
    return 0;
}
