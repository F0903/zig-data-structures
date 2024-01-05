const std = @import("std");
const llist = @import("linked_list.zig");
const dyn_array = @import("dynamic_array.zig");

fn linked_list(allocator: std.mem.Allocator) !void {
    var list = llist.LinkedList(u32).init(allocator);
    defer list.deinit();

    if (list.get_first()) |first_val| {
        std.debug.print("First value is: {}\n", .{first_val});
    } else {
        std.debug.print("List contained no values.\n", .{});
    }

    std.debug.print("Pushing values.\n", .{});
    try list.push(1);
    try list.push(10);
    try list.push(100);
    try list.push(1000);

    try list.remove(0);
    try list.remove(2);

    try list.insert(1, 20);
    try list.insert(0, 5);
    try list.insert(2, 50);

    std.debug.print("Getting values.\n", .{});
    for (0..list.count) |i| {
        const item = try list.get(i);
        std.debug.print("Value {} = {}\n", .{ i, item });
    }

    std.debug.print("Popping values.\n", .{});
    for (0..list.count) |i| {
        const item = list.pop();
        if (item) |it| {
            std.debug.print("Value {} = {}\n", .{ i, it });
        } else {
            std.debug.print("Value {} = None\n", .{i});
        }
    }
}

fn dynamic_array(allocator: std.mem.Allocator) !void {
    var array = try dyn_array.DynamicArray(u32).init(0, allocator);
    defer array.deinit();
    try array.push(20);
    try array.push(40);
    try array.push(60);
    try array.push(80);
    try array.push(100);

    for (0..array.count) |i| {
        const elem = array.get(i);
        std.debug.print("{} = {}", .{ i, elem });
    }
}

pub fn main() !void {
    std.debug.print("Hello\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.debug.print("Memory leak was detected!", .{});
        std.debug.panic("Memory leak was detected!", .{});
    };
    var allocator = gpa.allocator();

    std.debug.print("TESTING DYNAMIC ARRAY\n", .{});
    try dynamic_array(allocator);
    std.debug.print("\n\n", .{});
    std.debug.print("TESTING LINKED LIST\n", .{});
    try linked_list(allocator);
    std.debug.print("\n\n", .{});
}
