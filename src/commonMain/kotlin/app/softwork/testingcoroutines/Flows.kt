package app.softwork.testingcoroutines

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlin.coroutines.*

fun interface Cancelable {
    fun cancel()
}

fun <T> Flow<T>.collectingBlocking(action: (T) -> Unit, onCompletion: (Throwable?) -> Unit): Cancelable =
    collecting(action, onCompletion)

fun <T> Flow<T>.collecting(action: suspend (T) -> Unit, onCompletion: (Throwable?) -> Unit): Cancelable {
    val job = Job()

    CoroutineScope(job).launch {
        try {
            collect {
                action(it)
            }
            onCompletion(null)
        } catch (e: Throwable) {
            onCompletion(e)
            throw e
        }
    }

    return Cancelable {
        job.cancel()
    }
}

fun <T> List<T>.flowFrom() = asFlow()

public interface IteratorAsync<out T> : Cancelable {
    /**
     * Returns the next element in the iteration.
     */
    public suspend fun next(): T?
}

val EmptyContext = EmptyCoroutineContext

fun <T> Flow<T>.asAsyncIterable(context: CoroutineContext): IteratorAsync<T> =
    object : IteratorAsync<T> {
        private var cont: CancellableContinuation<Unit>

        init {
            println("CONT is null")
            val collecting = suspend {
                onStart {
                    suspendCancellableCoroutine {
                        cont = it
                    }
                }.collect {
                    println(it)
                    value = it
                    suspendCancellableCoroutine {
                        cont = it
                    }
                }
                value = null
            }
            println("Starting a new coroutine")
            cont = collecting.createCoroutine(Continuation(context) {
                it.getOrThrow()
            })
        }

        private var value: T? = null

        override fun cancel() {
            val cont = cont
            if (cont.isActive) {
                try {
                    cont.cancel()
                } catch (_: CancellationException) {
                }
            }
        }

        override suspend fun next(): T? {
            println("CALLED NEXT")
            println("local cont variable $cont")
            return if (cont.isActive) {
                cont.resume(Unit)
                value
            } else null
        }
    }

fun <T> IteratorAsync<T>.toFlow() = flow {
    while (true) {
        val next = next() ?: break
        emit(next)
    }
}

fun <T> List<T>.async(): IteratorAsync<T> = object : IteratorAsync<T> {
    val iterator = iterator()

    override fun cancel() {}

    override suspend fun next() = if (iterator.hasNext()) iterator.next() else null
}

suspend fun <T> runOnMain(action: suspend () -> T): T = withContext(Dispatchers.Main) {
    action()
}
