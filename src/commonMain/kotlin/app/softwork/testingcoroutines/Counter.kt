package app.softwork.testingcoroutines

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlin.time.Duration.Companion.seconds

class Counter {
    var current = 0
        private set

    val flow = flow {
        while (true) {
            emit(current)
            current++
        }
    }

    class AutoMax(private val max: Int) {
        private var current = 0
        val flow = flow {
            while (current < max) {
                emit(current)
                current += 1
                delay(1.seconds)
            }
        }
    }

    fun zip(autoMax: AutoMax) = flow.zip(autoMax.flow) { n, _ ->
        n
    }
}
