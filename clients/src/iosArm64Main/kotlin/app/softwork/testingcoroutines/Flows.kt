package app.softwork.testingcoroutines

import kotlinx.coroutines.flow.*


suspend fun <T> Flow<T>.collecting(action: (T) -> Unit) =
    collect {
        action(it)
    }

fun <T> List<T>.flowFrom() = asFlow()
