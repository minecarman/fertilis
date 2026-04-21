const errorHandler = (err, req, res, next) => {
  const numericStatusCode = Number(err.statusCode);
  err.statusCode = Number.isFinite(numericStatusCode) ? numericStatusCode : 500;
  err.status = err.status || 'error';

  // Log error (for server console)
  console.error('ERROR 💥:', {
    statusCode: err.statusCode,
    message: err.message,
    stack: err.stack,
  });

  // Send client response
  res.status(err.statusCode).json({
    status: err.status,
    error: err.message || 'Sunucu hatası',
  });
};

export default errorHandler;
