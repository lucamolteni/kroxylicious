/*
 * Copyright Kroxylicious Authors.
 *
 * Licensed under the Apache Software License version 2.0, available at http://www.apache.org/licenses/LICENSE-2.0
 */

package io.kroxylicious.filter.encryption.dek;

public class BufferTooSmallException extends RuntimeException {
    public BufferTooSmallException() {
        super();
    }

    @Override
    public synchronized Throwable fillInStackTrace() {
        return null;
    }
}
