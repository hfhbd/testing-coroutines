package app.softwork.testingcoroutines

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import kotlin.test.*
import kotlin.time.Duration.Companion.seconds

@ExperimentalCoroutinesApi
class CounterTest {
    @Test
    fun loadTest() = runTest {
        val normal = Counter()
        normal.flow.take(2).collect()
        assertEquals(1, normal.current)

        val asyncCounter = Counter()
        val async = asyncCounter.flow.asAsyncIterable(coroutineContext)
        assertEquals(0, async.next())
        assertEquals(1, async.next())
        assertEquals(1, asyncCounter.current)
    }

    @Test
    fun maxTest() = runTest {
        val autoMax = Counter.AutoMax(10)

        val result = autoMax.flow.toList()
        assertEquals(List(10) { it }, result)
    }

    @Test
    fun maxTestZip() = runTest {
        val normal = Counter()
        val autoMax = Counter.AutoMax(10)

        val result = normal.zip(autoMax)
        assertEquals(List(10) { it }, result.toList())
    }

    @Test
    fun stateFlow() = runTest {
        val flow1 = MutableStateFlow(1)
        val flow2 = MutableStateFlow("B")

        val s = flow1.combine(flow2) { i, s ->
            i.toString() + s
        }
        val result = async {
            s.take(10).toList()
        }
        repeat(5) {
            flow1.value = it
            runCurrent()
        }
        "ABCDE".forEach {
            flow2.value = it.toString()
            runCurrent()
        }
        assertEquals(listOf("0B", "1B", "2B", "3B", "4B", "4A", "4B", "4C", "4D", "4E"), result.await())
    }

    @Test
    fun stateFlowAsync() = runTest {
        val flow = MutableStateFlow(1)

        val s = flow.asAsyncIterable(coroutineContext)

        val results = async {
            buildList {
                repeat(10) {
                    val next = s.next()!!
                    add(next)
                }
                s.cancel()
            }
        }
        repeat(10) {
            flow.value = it
            println("SET VALUE $it")
            runCurrent()
            println("AFTER RUNCURRENT $it")
            delay(1.seconds)
        }
        assertEquals(List(10) { it }, results.await())
    }

    @Test
    fun stateFlowAsyncCombine() = runTest {
        val flow1 = MutableStateFlow(1)
        val flow2 = MutableStateFlow("B")

        val s = flow1.combine(flow2) { i, s ->
            i.toString() + s
        }.asAsyncIterable(coroutineContext)

        val results = async {
            buildList {
                repeat(10) {
                    val next = s.next()!!
                    add(next)
                }
                s.cancel()
            }
        }

        repeat(5) {
            flow1.value = it
            runCurrent()
        }
        "ABCDE".forEach {
            flow2.value = it.toString()
            runCurrent()
        }
        assertEquals(listOf("0B", "1B", "2B", "3B", "4B", "4A", "4B", "4C", "4D", "4E"), results.await())
    }
}
