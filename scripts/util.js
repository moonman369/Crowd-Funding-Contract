const sleep = async (seconds) => {
  return new Promise((res, rej) => {
    setTimeout(() => {
      res();
    }, seconds * 1000);
  });
};

module.exports = {
  sleep,
};
