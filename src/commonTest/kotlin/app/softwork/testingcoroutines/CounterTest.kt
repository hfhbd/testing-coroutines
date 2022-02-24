package app.softwork.testingcoroutines

import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import kotlin.test.*

class CounterTest {
    @Test
    fun loadTest() = runTest {
        val normal = Counter()
        normal.flow.take(2).collect()
        assertEquals(1, normal.current)

        val asyncCounter = Counter()
        val async = asyncCounter.flow.asAsyncIterable()
        assertEquals(0, async.next())
        assertEquals(1, async.next())
        val calledButWaitsForNext = 1
        assertEquals(1 + calledButWaitsForNext, asyncCounter.current)
    }
}
