const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub const ListError = error{
    IndexOutOfBounds,
    EmptyList,
    OutOfMemory,
};

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        first: ?*Node(T),
        length: usize,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .first = null,
                .length = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            var current = self.first;
            while (current) |node| {
                var next = node.next;
                self.allocator.destroy(node);
                current = next;
            }
        }

        pub fn len(self: Self) usize {
            return self.length;
        }

        pub fn empty(self: Self) bool {
            return self.length == 0;
        }

        pub fn push(self: *Self, element: T) ListError!void {
            const new_node = try Node(T).init(self.allocator, element);

            if (self.first == null) {
                self.first = new_node;
            } else {
                var last_node = try self.get_last_node();
                last_node.next = new_node;
            }

            self.length += 1;
        }

        pub fn get(self: Self, index: usize) ListError!T {
            const node = try self.get_node_at_index(index);
            return node.value;
        }

        pub fn pop(self: *Self) ListError!T {
            if (self.len() == 0) {
                return ListError.EmptyList;
            }
            if (self.len() == 1) {
                return self.destroy_node(&self.first);
            } else {
                var penultimate = self.get_node_at_index(self.len() - 2) catch unreachable;
                return self.destroy_node(&penultimate.next);
            }
        }

        fn destroy_node(self: *Self, node: *?*Node(T)) T {
            const value = node.*.?.value;
            node.*.?.deinit(self.allocator);
            self.length -= 1;
            node.* = null;
            return value;
        }

        fn get_last_node(self: Self) ListError!*Node(T) {
            return self.get_node_at_index(self.len() - 1);
        }

        fn get_node_at_index(self: Self, index: usize) ListError!*Node(T) {
            if (index >= self.len()) {
                return ListError.IndexOutOfBounds;
            }

            var current = self.first.?;
            for (0..index) |_| {
                current = current.next.?;
            }
            return current;
        }
    };
}

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        next: ?*Node(T),
        value: T,

        pub fn init(allocator: Allocator, element: T) ListError!*Self {
            var node = try allocator.create(Self);
            node.next = null;
            node.value = element;

            return node;
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            allocator.destroy(self);
        }
    };
}
