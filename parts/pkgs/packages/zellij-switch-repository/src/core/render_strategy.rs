/// Declaration of the common types used across this plugin's implementation.
use super::{PluginUpdateLoop, Result};
use std::ops::{BitAnd, BitOr};

impl Default for PluginUpdateLoop {
    fn default() -> Self {
        PluginUpdateLoop::NoUpdates
    }
}

impl From<PluginUpdateLoop> for Result {
    fn from(value: PluginUpdateLoop) -> Self {
        Ok(value)
    }
}

impl PluginUpdateLoop {
    pub fn as_bool(&self) -> bool {
        match self {
            PluginUpdateLoop::MarkDirty => true,
            PluginUpdateLoop::NoUpdates => false,
        }
    }

    /// Short-circuiting `&&` operator for [RenderStrategy].
    pub fn and_then<F>(&self, then_fn: F) -> Self
    where
        F: FnOnce() -> Self,
    {
        if self.as_bool() {
            then_fn()
        } else {
            *self
        }
    }

    /// Short-circuiting `||` operator for [RenderStrategy].
    pub fn or_else<F>(&self, else_fn: F) -> Self
    where
        F: FnOnce() -> Self,
    {
        if self.as_bool() {
            *self
        } else {
            else_fn()
        }
    }
}

impl From<bool> for PluginUpdateLoop {
    fn from(value: bool) -> Self {
        match value {
            true => Self::MarkDirty,
            false => Self::NoUpdates,
        }
    }
}

impl BitAnd for PluginUpdateLoop {
    type Output = PluginUpdateLoop;

    fn bitand(self, rhs: Self) -> Self::Output {
        (self.as_bool() & rhs.as_bool()).into()
    }
}

impl BitOr for PluginUpdateLoop {
    type Output = PluginUpdateLoop;

    fn bitor(self, rhs: Self) -> Self::Output {
        (self.as_bool() | rhs.as_bool()).into()
    }
}

impl BitOr<Result> for PluginUpdateLoop {
    type Output = Result;

    fn bitor(self, rhs: Result) -> Self::Output {
        match rhs {
            Ok(value) => Ok(self | value),
            err => err,
        }
    }
}
