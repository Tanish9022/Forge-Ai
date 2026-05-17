import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = '7d';

export function signToken(userId) {
  if (!JWT_SECRET) throw new Error('JWT_SECRET is required');
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

export function verifyToken(token) {
  if (!JWT_SECRET) throw new Error('JWT_SECRET is required');
  return jwt.verify(token, JWT_SECRET);
}
