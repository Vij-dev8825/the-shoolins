// Falls back to a console-logged OTP when MSG91 credentials aren't configured,
// so the full login flow is testable locally before real SMS is wired up.
const devOtps = new Map();

function isConfigured() {
  return Boolean(process.env.MSG91_AUTH_KEY && process.env.MSG91_TEMPLATE_ID);
}

function toMsg91Mobile(mobile) {
  return mobile.length === 10 ? `91${mobile}` : mobile;
}

function generateDevOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function sendOtp(mobile) {
  if (!isConfigured()) {
    const otp = generateDevOtp();
    devOtps.set(mobile, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });
    console.log(`[dev-otp] OTP for ${mobile}: ${otp}`);
    return { devOtp: otp };
  }

  const params = new URLSearchParams({
    template_id: process.env.MSG91_TEMPLATE_ID,
    mobile: toMsg91Mobile(mobile),
    authkey: process.env.MSG91_AUTH_KEY,
  });
  if (process.env.MSG91_SENDER_ID) {
    params.set("sender", process.env.MSG91_SENDER_ID);
  }

  const response = await fetch(`https://control.msg91.com/api/v5/otp?${params}`);
  const data = await response.json();
  if (data.type !== "success") {
    throw new Error(data.message || "Failed to send OTP");
  }
  return {};
}

async function verifyOtp(mobile, otp) {
  if (!isConfigured()) {
    const entry = devOtps.get(mobile);
    if (!entry || entry.expiresAt < Date.now()) {
      return false;
    }
    const valid = entry.otp === otp;
    if (valid) {
      devOtps.delete(mobile);
    }
    return valid;
  }

  const params = new URLSearchParams({
    mobile: toMsg91Mobile(mobile),
    otp,
    authkey: process.env.MSG91_AUTH_KEY,
  });
  const response = await fetch(`https://control.msg91.com/api/v5/otp/verify?${params}`);
  const data = await response.json();
  return data.type === "success";
}

module.exports = { sendOtp, verifyOtp, isConfigured };
