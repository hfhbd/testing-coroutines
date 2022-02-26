package app.softwork.testingcoroutines

import kotlinx.coroutines.flow.*

class Counter {
    var current = 0
        private set

    val flow = flow {
        while (true) {
            emit(current)
            current++
        }
    }
}
