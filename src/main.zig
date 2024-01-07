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

    const time = std.time.Instant;

    const before_push = try time.now();
    for (0..10000000) |i| {
        try array.push(@intCast(i));
    }
    const after_push = try time.now();
    const push_total = after_push.since(before_push);
    std.debug.print("Pusing took {}us\n", .{push_total / 1000});

    const before_remove_first = try time.now();
    const first = array.remove(0);
    _ = first;
    const after_remove_first = try time.now();
    const total_remove_first = after_remove_first.since(before_remove_first);

    const before_remove_last = try time.now();
    const last = array.remove(array.count - 1);
    _ = last;
    const after_remove_last = try time.now();
    const total_remove_last = after_remove_last.since(before_remove_last);

    std.debug.print("Removing first item took {}us\nRemoving last item took {}us\n", .{ total_remove_first / 1000, total_remove_last / 1000 });

    try array.push_slice(&[_]u32{ 33, 66, 99, 132 });

    for (0..array.count) |i| {
        const elem = array.get(i).*;
        std.debug.print("{} = {}\n", .{ i, elem });
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
