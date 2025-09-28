import express from "express";
import bcrypt from "bcryptjs";
import User from "../models/User.js";

const router = express.Router();

// Signup
router.post("/signup", async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser)
      return res.status(400).json({ message: "User already exists" });

    // hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // create new user
    const newUser = new User({ name, email, password: hashedPassword });
    await newUser.save();

    res.json({ message: "User created" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // find user
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    // check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(401).json({ message: "Invalid credentials" });

    // return user info
    res.json({ id: user._id, name: user.name, email: user.email });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
