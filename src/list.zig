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

        pub fn insert(self: *Self, element: T, index: usize) ListError!void {
            if (index >= self.len()) {
                return self.push(element);
            }
            const new_node = try Node(T).init(self.allocator, element);

            if (index == 0) {
                new_node.next = self.first;
                self.first = new_node;
            } else {
                var previous = self.get_node_at_index(index - 1) catch unreachable;
                new_node.next = previous.next;
                previous.next = new_node;
            }

            self.length += 1;
        }

        pub fn remove(self: *Self, index: usize) ListError!T {
            if (index >= self.len()) {
                return self.pop();
            }

            if (index == 0) {
                const next = self.first.?.next;
                const value = self.unlink_node(&self.first);
                self.first = next;
                return value;
            }

            const previous = self.get_node_at_index(index - 1) catch unreachable;
            const next = previous.next.?.next;
            const value = self.unlink_node(&previous.next);
            previous.next = next;
            return value;
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
                return self.unlink_node(&self.first);
            } else {
                var previous = self.get_node_at_index(self.len() - 2) catch unreachable;
                return self.unlink_node(&previous.next);
            }
        }

        fn unlink_node(self: *Self, node: *?*Node(T)) T {
            const value = node.*.?.value;
            node.*.?.deinit(self.allocator);
            self.length -= 1;
            node.* = null;
            return value;
        }

        fn link_node(self: *Self, holder: *?*Node(T), node: *Node(T)) void {
            _ = self;
            holder.* = node;
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

        pub fn for_each_element(
            self: Self,
            context: anytype,
            callback: *const fn (T, @TypeOf(context)) bool,
        ) usize {
            var current = self.first;
            var iterated: usize = 0;
            while (current) |node| {
                iterated += 1;
                if (!callback(node.value, context)) {
                    break;
                }
                current = node.next;
            }

            return iterated;
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
