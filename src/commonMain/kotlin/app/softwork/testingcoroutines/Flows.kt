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

public interface IteratorAsync<out T> : Cancelable {
    /**
     * Returns the next element in the iteration.
     */
    public suspend fun next(): T?
}

val EmptyContext = EmptyCoroutineContext

fun <T> Flow<T>.asAsyncIterable(context: CoroutineContext = EmptyContext): IteratorAsync<T> = object : IteratorAsync<T> {
    private var job: Job? = null
    private val fixForInitDelay = 1
    private val requester = MutableSharedFlow<(T) -> Unit>(replay = fixForInitDelay)

    override fun cancel() {
        job?.cancel()
    }

    private fun c() = cancel()

    override suspend fun next(): T? {
        if (job == null) {
            this.job = onCompletion {
                c()
            }.zip(requester) { t, requester ->
                requester(t)
            }.launchIn(CoroutineScope(context))
        }
        return if (job!!.isActive) {
            try {
                val deferred = CompletableDeferred<T>(job)
                requester.emit { deferred.complete(it) }
                deferred.await()
            } catch (_: CancellationException) {
                null
            }
        } else {
            null
        }
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
