const std = @import("std");
const Allocator = std.mem.Allocator;

fn Node(comptime T: type) type {
    return struct {
        value: T,
        next: ?*Node(T),
        prev: ?*Node(T),

        pub fn init(value: T, allocator: Allocator) !*Node(T) {
            var self = try allocator.create(Node(T));
            self.* = .{ .value = value, .next = null, .prev = null };
            return self;
        }

        pub fn deinit(self: *Node(T), allocator: Allocator) void {
            if (self.prev) |prev| {
                prev.next = self.next;
                if (self.next) |next| {
                    next.prev = prev;
                }
            }
            allocator.destroy(self);
        }

        pub fn deinit_children(self: *Node(T), allocator: Allocator) void {
            if (self.next) |next| {
                next.deinit_children(allocator);
                self.next = null;
            }
            if (self.prev) |prev| {
                prev.next = null;
            }
            allocator.destroy(self);
        }

        pub fn remove_child(self: *Node(T), allocator: Allocator) void {
            self.next.deinit(allocator);
            self.next = null;
        }
    };
}

pub fn LinkedList(comptime T: type) type {
    return struct {
        allocator: Allocator,
        start: ?*Node(T),
        tip: ?*Node(T),
        count: usize,

        pub fn init(allocator: Allocator) !LinkedList(T) {
            return .{
                .allocator = allocator,
                .start = null,
                .tip = null,
                .count = 0,
            };
        }

        pub fn deinit(self: *LinkedList(T)) void {
            if (self.start) |start| {
                start.deinit_children(self.allocator);
            }
            self.start = null;
            self.tip = null;
            self.count = 0;
        }

        pub fn push(self: *LinkedList(T), value: T) !void {
            if (self.tip == null) {
                var start = try Node(T).init(value, self.allocator);
                self.start = start;
                self.tip = start;
                self.count += 1;
                return;
            }

            var new = try Node(T).init(value, self.allocator);
            new.value = value;
            new.prev = self.tip;
            self.tip.?.next = new;
            self.tip = new;

            self.count += 1;
        }

        pub fn pop(self: *LinkedList(T)) ?T {
            var old_tip = self.tip orelse return null;
            const val = old_tip.value;
            if (old_tip.prev == null) {
                self.start = null;
                self.tip = null;
            } else {
                self.tip = old_tip.prev;
            }
            old_tip.deinit(self.allocator);
            self.count -= 1;
            return val;
        }

        pub fn get_first(self: *LinkedList(T)) ?T {
            return (self.start orelse return null).value;
        }

        pub fn get_last(self: *LinkedList(T)) ?T {
            return (self.tip orelse return null).value;
        }

        pub fn get(self: *LinkedList(T), index: usize) ?T {
            var current = self.start orelse return null;
            for (0..self.count) |i| {
                if (i == index)
                    return current.value;
                if (current.next) |next_node| {
                    current = next_node;
                } else break;
            }
            return null;
        }
    };
}

test "linked list" {
    const expect = @import("std").testing.expect;

    var list = try LinkedList(u32).init(std.testing.allocator);
    defer list.deinit();

    try list.push(1);
    try list.push(10);
    try list.push(100);
    try list.push(1000);

    const first = list.get_first();
    try expect(first == 1);

    const last = list.get_last();
    try expect(last == 1000);

    for (0..list.count) |i| {
        const item = list.get(i);
        switch (i) {
            0 => try expect(item == 1),
            1 => try expect(item == 10),
            2 => try expect(item == 100),
            3 => try expect(item == 1000),
            else => std.log.warn("Unexpected value in test. Might have forgotten to update the test.", .{}),
        }
    }

    var i: u32 = 0;
    while (list.pop()) |item| {
        switch (i) {
            0 => try expect(item == 1000),
            1 => try expect(item == 100),
            2 => try expect(item == 10),
            3 => try expect(item == 1),
            else => std.log.warn("Unexpected value in test. Might have forgotten to update the test.", .{}),
        }
        i += 1;
    }
}
