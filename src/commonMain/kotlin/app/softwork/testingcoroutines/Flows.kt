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
        println("CALLED NEXT job: $job requestors: ${requester.subscriptionCount.value}")
        if (job == null) {
            println("INIT job: $job requestors: ${requester.subscriptionCount.value}")
            this.job = onCompletion {
                c()
            }.onEach {
                println("ON EACH GOT $it")
            }.zip(requester) { t, requester ->
                println("ZIP GOT $t $requester")
                requester(t)
            }.launchIn(CoroutineScope(context))
            println("INIT DONE job: $job requestors: ${requester.subscriptionCount.value}")
        }
        return if (job!!.isActive) {
            println("JOB ACTIVE: REQUESTING requestors: ${requester.subscriptionCount.value}\"")
            val deferred = CompletableDeferred<T>(job)
            println("SEND NEW VALUE")
            requester.emit {
                println("GOT NEW VALUE $it")
                deferred.complete(it)
            }
            println("WAITING FOR NEW VALUE $deferred")
            val t = deferred.await()
            println("RETURN NEW VALUE $t")
            t
        } else {
            println("INACTIVE RETURN null")
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
