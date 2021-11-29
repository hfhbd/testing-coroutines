package app.softwork.testingcoroutines

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

fun interface Cancelable {
    fun cancel()
}

fun <T> Flow<T>.collecting(action: (T) -> Unit, onCompletion: (Throwable?) -> Unit): Cancelable {
    val job = Job()
    onEach {
        action(it)
    }.onCompletion {
        onCompletion(it)
    }.launchIn(CoroutineScope(job))
    return Cancelable {
        job.cancel()
    }
}

fun <T> List<T>.flowFrom() = asFlow()
