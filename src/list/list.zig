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
                current = node.deinit();
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
                last_node.link(new_node);
            }

            self.length += 1;
        }

        pub fn insert(self: *Self, element: T, index: usize) ListError!void {
            if (index >= self.len()) {
                return self.push(element);
            }
            const new_node = try Node(T).init(self.allocator, element);

            if (index == 0) {
                new_node.link(self.first);
                self.first = new_node;
            } else {
                var previous = self.get_node_at_index(index - 1) catch unreachable;
                new_node.link(previous.get_next());
                previous.link(new_node);
            }

            self.length += 1;
        }

        pub fn remove(self: *Self, index: usize) ListError!T {
            if (self.length <= 1 or index == 0) {
                return self.remove_first();
            }
            if (index >= self.length) {
                return ListError.IndexOutOfBounds;
            }

            const previous = try self.get_node_at_index(index - 1);
            const to_remove = previous.get_next().?;

            const value = to_remove.get_value();
            previous.link(to_remove.deinit());

            self.length -= 1;

            return value;
        }

        pub fn pop(self: *Self) ListError!T {
            return self.remove(self.length - 1);
        }

        fn remove_first(self: *Self) ListError!T {
            if (self.length == 0) {
                return ListError.EmptyList;
            }

            const to_remove = self.first.?;

            const value = to_remove.get_value();
            self.first = to_remove.deinit();

            self.length -= 1;
            return value;
        }

        pub fn get(self: Self, index: usize) ListError!T {
            const node = try self.get_node_at_index(index);
            return node.get_value();
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
                current = current.get_next().?;
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
                if (!callback(node.get_value(), context)) {
                    break;
                }

                current = node.get_next();
            }

            return iterated;
        }

        pub fn iterator(self: Self) Iterator(T) {
            return Iterator(T).init(self.first);
        }

        pub fn push_slice(self: *Self, slice: []T) ListError!void {
            try self.push(slice[0]);

            var last_node = try self.get_last_node();
            for (slice[1..]) |element| {
                var to_add = try Node(T).init(self.allocator, element);
                last_node.link(to_add);
                self.length += 1;
                last_node = to_add;
            }
        }
    };
}

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        _next: ?*Node(T),
        _value: T,
        _allocator: Allocator,

        pub fn init(allocator: Allocator, element: T) ListError!*Self {
            var node = try allocator.create(Self);

            node._allocator = allocator;
            node._next = null;
            node._value = element;

            return node;
        }

        pub fn deinit(self: *Self) ?*Node(T) {
            const next = self._next;
            self._allocator.destroy(self);
            return next;
        }

        pub fn link(self: *Self, node: ?*Node(T)) void {
            self._next = node;
        }

        pub fn get_next(self: Self) ?*Node(T) {
            return self._next;
        }

        pub fn get_value(self: Self) T {
            return self._value;
        }
    };
}

fn Iterator(comptime T: type) type {
    return struct {
        const Self = @This();

        _node: ?*Node(T),

        fn init(node: ?*Node(T)) Self {
            return Self{
                ._node = node,
            };
        }

        pub fn next(self: *Self) ?T {
            const node = self._node orelse return null;
            self._node = node.get_next();
            return node.get_value();
        }
    };
}

test {
    _ = @import("tests.zig");
}
