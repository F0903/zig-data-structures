const std = @import("std");
const llist = @import("linked_list.zig");

pub fn main() !void {
    std.debug.print("Hello\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.debug.print("Memory leak was detected!", .{});
        std.debug.panic("Memory leak was detected!", .{});
    };
    var allocator = gpa.allocator();

    var list = try llist.LinkedList(u32).init(allocator);
    defer list.deinit();

    if (list.get_first()) |first_val| {
        std.debug.print("First value is: {}\n", .{first_val});
    } else {
        std.debug.print("List contained no values.\n", .{});
    }

    std.debug.print("Pusing value.\n", .{});
    try list.push(1);
    try list.push(10);
    try list.push(100);

    for (0..list.count) |i| {
        const item = list.pop();
        if (item) |it| {
            std.debug.print("Value {} = {}\n", .{ i, it });
        } else {
            std.debug.print("Value {} = None\n", .{i});
        }
    }
}
