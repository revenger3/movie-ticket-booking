require("dotenv").config();
const express = require("express");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// ✅ Test route to check server connectivity
app.get("/", (req, res) => {
  res.send("Backend is running!");
});

// 🔵 Create PaymentIntent
app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency, userId, movieId, theaterId, showtimeId, selectedSeats } = req.body;

    if (!amount || !currency) {
      return res.status(400).json({ error: "Amount and currency are required" });
    }

    const paymentAmount = parseInt(amount);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: paymentAmount, // smallest currency unit
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        userId: userId || "unknown",
        movieId: movieId || "unknown",
        theaterId: theaterId || "unknown",
        showtimeId: showtimeId || "unknown",
        seats: selectedSeats ? selectedSeats.join(",") : "",
      },
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error("❌ Stripe error:", error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server running on http://0.0.0.0:${PORT}`);
});
