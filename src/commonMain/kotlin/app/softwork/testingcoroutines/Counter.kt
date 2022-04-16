package app.softwork.testingcoroutines

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlin.time.Duration.Companion.seconds

class Counter {
    private val _state = MutableStateFlow(0)
    val state = _state.asStateFlow()

    fun increase() {
        _state.getAndUpdate { it + 1 }
    }

    val state2 = state.map {
        "$it $it"
    }

    val username = MutableStateFlow("")
    val password = MutableStateFlow("")
    val isLonger = password.map {
        it.length >= 4
    }
    val isValid = username.combine(password) { user, password ->
        user.isNotBlank() && password.isNotBlank()
    }

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
