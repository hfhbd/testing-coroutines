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
        private val scope = CoroutineScope(context)

        private lateinit var value: CompletableDeferred<T>

        private val collector: Job = scope.launch(start = CoroutineStart.LAZY) {
            collect {
                nextCall.join()
                value.complete(it)
                nextCall = newJob()
            }
            c()
        }
        private fun newJob() = Job(collector)
        private fun c() = cancel()
        private var nextCall: CompletableJob = Job(collector)

        override fun cancel() {
            collector.cancel()
        }

        override suspend fun next(): T? {
            collector.start()
            return if (collector.isActive) {
                value = CompletableDeferred(collector)
                nextCall.complete()
                value.await()
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
