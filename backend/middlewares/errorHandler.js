const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Log error (for server console)
  if (err.statusCode === 500) {
    console.error('ERROR 💥:', err);
  }

  // Send client response
  res.status(err.statusCode).json({
    status: err.status,
    error: err.message || 'Sunucu hatası',
  });
};

export default errorHandler;
