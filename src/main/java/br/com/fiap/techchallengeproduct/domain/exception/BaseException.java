package br.com.fiap.techchallengeproduct.domain.exception;

public class BaseException extends RuntimeException {
    public BaseException(String message) {
        super(message);
    }
}