package app.softwork.testingcoroutines

import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import kotlin.test.*

class FlowsTest {
    @Test
    fun toAsyncTest() = runTest {
        val called = mutableListOf<Int>()
        val expected = flow {
            repeat(3) {
                emit(it)
                called += it
            }
        }
        val iterator = expected.asAsyncIterable(coroutineContext)
        val values = buildList {
            while (true) {
                val next = iterator.next() ?: break
                add(next)
            }
        }
        assertEquals(listOf(0, 1, 2), values)
        assertEquals(listOf(0, 1, 2), called)
    }

    @Test
    fun toAsyncCancelTest() = runTest {
        val computed = mutableListOf<Int>()
        val expected = flowOf(1, 2, 3).onEach {
            computed += it
        }
        val iterator = expected.asAsyncIterable(coroutineContext)
        val next = iterator.next()
        assertNotNull(next)
        iterator.cancel()
        assertEquals(1, next)
        assertEquals(listOf(1), computed)
    }

    @Test
    fun toAsyncCancelNoEmitsTest() = runTest {
        val computed = mutableListOf<Int>()
        val expected = flowOf(1, 2, 3).onEach {
            computed += it
        }
        val iterator = expected.asAsyncIterable(coroutineContext)
        iterator.cancel()
        assertEquals(emptyList(), computed)
    }

    @Test
    fun iterableToFlowTest() = runTest {
        val iterable = flowOf(1, 2, 3).asAsyncIterable(coroutineContext)
        assertEquals(listOf(1, 2, 3), iterable.toFlow().toList())
    }
}
