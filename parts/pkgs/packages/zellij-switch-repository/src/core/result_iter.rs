use super::{Result, ResultIterator};
use std::iter::Map;

impl<I: Iterator, F> ResultIterator for Map<I, F>
where
    F: FnMut(I::Item) -> Result,
{
    fn try_consume(self: &mut Self) -> Result {
        self.try_fold(Default::default(), std::ops::BitOr::bitor)
    }
}
