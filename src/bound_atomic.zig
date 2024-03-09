const std = @import("std");

pub const BoundAtomic = struct {
    min: i32,
    max: i32,
    integer: std.atomic.Atomic(i32),

    pub fn new(min: i32, max: i32) BoundAtomic {
        return BoundAtomic{
            .min = min,
            .max = max,
            .integer = std.atomic.Atomic(i32).init(min),
        };
    }

    pub fn nextVal(self: *BoundAtomic) i32 {
        while (true) {
            const current = self.integer.load(.SeqCst);
            const next = if (current == self.max) self.min else current + 1;
            if (self.integer.compareAndSwap(current, next, .SeqCst, .SeqCst) == null) {
                return next;
            }
        }
    }
};
