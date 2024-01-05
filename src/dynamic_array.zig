const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Error = error{};

        const Self = @This();

        data: []T,
        count: usize,
        allocator: Allocator,

        pub fn init(init_size: usize, allocator: Allocator) !Self {
            var data = try allocator.alloc(T, @max(init_size, 1));
            return .{ .data = data, .count = 0, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        fn resize(self: *Self, new_size: usize) !void {
            const half_size = new_size >> 1;
            const total_new_size = new_size + half_size; // Make it 1.5 times bigger.
            const result = self.allocator.resize(self.data, total_new_size);
            if (!result) {
                var new_mem = try self.allocator.alloc(T, total_new_size);
                @memcpy(new_mem.ptr, self.data);
                self.allocator.free(self.data);
                self.data = new_mem;
            }
        }

        fn ensure_capacity(self: *Self, new_objects_count: usize) !void {
            const new_size = self.count + new_objects_count;
            if (new_size <= self.data.len) return;
            return self.resize(new_size);
        }

        pub fn push(self: *Self, object: T) !void {
            try self.ensure_capacity(1);
            self.data[self.count] = object;
            self.count += 1;
        }

        pub fn get_front(self: *Self) T {
            return self.data[self.count];
        }

        pub fn get(self: *Self, index: usize) T {
            return self.data[index];
        }

        pub fn set(self: *Self, index: usize, value: T) void {
            self.data[index] = value;
        }

        pub fn insert(self: *Self, index: usize, value: T) !void {
            try self.ensure_capacity(1);
            var last = self.data[index];
            for (index + 1..self.count + 1) |i| {
                var item_ptr = self.data[i];
                var old = item_ptr.*;
                item_ptr.* = last;
                last = old;
            }
            self.data[index] = value;
        }
    };
}
