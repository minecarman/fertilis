class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    const numericStatusCode = Number(statusCode);
    this.statusCode = Number.isFinite(numericStatusCode) ? numericStatusCode : 500;
    this.status = `${this.statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export default AppError;
