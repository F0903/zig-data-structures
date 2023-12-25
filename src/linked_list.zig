const std = @import("std");
const Allocator = std.mem.Allocator;

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        next: ?*Node(T),
        prev: ?*Node(T),

        pub fn init(value: T, allocator: Allocator) !*Node(T) {
            var self = try allocator.create(Node(T));
            self.* = .{ .value = value, .next = null, .prev = null };
            return self;
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            if (self.prev) |prev| {
                prev.next = self.next;
            }
            if (self.next) |next| {
                next.prev = self.prev;
            }
            allocator.destroy(self);
        }

        pub fn deinit_children(self: *Self, allocator: Allocator) void {
            if (self.next) |next| {
                next.deinit_children(allocator);
                self.next = null;
            }
            if (self.prev) |prev| {
                prev.next = null;
            }
            allocator.destroy(self);
        }
    };
}

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        const Errors = error{
            IndexOutOfRange,
        };

        allocator: Allocator,
        start: ?*Node(T),
        tip: ?*Node(T),
        count: usize,

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .start = null,
                .tip = null,
                .count = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.start) |start| {
                start.deinit_children(self.allocator);
            }
            self.start = null;
            self.tip = null;
            self.count = 0;
        }

        pub fn push(self: *Self, value: T) !void {
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

        pub fn pop(self: *Self) ?T {
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

        pub fn get_first(self: *Self) ?T {
            return (self.start orelse return null).value;
        }

        pub fn get_last(self: *Self) ?T {
            return (self.tip orelse return null).value;
        }

        fn get_node(self: *Self, index: usize) !*Node(T) {
            var current = self.start orelse return Errors.IndexOutOfRange;
            for (0..self.count) |i| {
                if (i == index)
                    return current;
                if (current.next) |next_node| {
                    current = next_node;
                } else break;
            }
            return Errors.IndexOutOfRange;
        }

        pub fn get(self: *Self, index: usize) !T {
            const node = try self.get_node(index);
            return node.value;
        }

        pub fn remove(self: *Self, index: usize) !void {
            var node = try self.get_node(index);
            if (index == 0) {
                self.start = node.next;
            }
            if (node == self.tip) {
                self.tip = node.prev;
            }
            node.deinit(self.allocator);
            self.count -= 1;
        }

        pub fn insert(self: *Self, index: usize, value: T) !void {
            var new_node = try Node(T).init(value, self.allocator);
            if (index == 0) {
                var old_start = self.start orelse return Errors.IndexOutOfRange;
                self.start = new_node;
                old_start.prev = new_node;
                new_node.next = old_start;
                self.count += 1;
                return;
            }

            if (index == self.count) {
                self.tip = new_node;
            }
            var node = try self.get_node(index - 1);
            new_node.next = node.next;
            new_node.prev = node;
            if (node.next) |old_next| {
                old_next.prev = new_node;
            }
            node.next = new_node;
            self.count += 1;
        }
    };
}

test "linked list" {
    const expect = @import("std").testing.expect;

    var list = LinkedList(u32).init(std.testing.allocator);
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
        const item = try list.get(i);
        switch (i) {
            0 => try expect(item == 1),
            1 => try expect(item == 10),
            2 => try expect(item == 100),
            3 => try expect(item == 1000),
            else => std.log.warn("Unexpected extra value in test. Might have forgotten to update the test.", .{}),
        }
    }

    var index: u32 = 0;
    while (list.pop()) |item| {
        switch (index) {
            0 => try expect(item == 1000),
            1 => try expect(item == 100),
            2 => try expect(item == 10),
            3 => try expect(item == 1),
            else => std.log.warn("Unexpected extra value in test. Might have forgotten to update the test.", .{}),
        }
        index += 1;
    }

    try list.push(5);
    try list.push(10);
    try list.push(15);
    try list.remove(1);
    for (0..list.count) |i| {
        const item = try list.get(i);
        switch (i) {
            0 => try expect(item == 5),
            1 => try expect(item == 15),
            else => std.log.warn("Unexpected extra value in test. Might have forgotten to update the test.", .{}),
        }
    }

    try list.insert(2, 500);
    var second = try list.get(2);
    try expect(second == 500);
}
