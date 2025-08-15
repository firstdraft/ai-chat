require "ai-chat"
require "dotenv/load"
require "amazing_print"

c = AI::Chat.new
c.model = "o4-mini"

c.system("You are an expert nutritionist. Do your best to estimate the number of calories in the user-provided image(s).")

c.user("How many calories are in the food items in this image?", image: "examples/1.webp")

c.schema = '{
  "name": "meal_nutrition_estimate",
  "schema": {
    "type": "object",
    "properties": {
      "rationale": {
        "type": "string",
        "description": "Explanation of the estimation made for the nutritional values of the items and totals."
      },
      "items": {
        "type": "array",
        "description": "List of food items with their corresponding macronutrient and calorie values.",
        "items": {
          "type": "object",
          "properties": {
            "description": {
              "type": "string",
              "description": "Description or name of the food item."
            },
            "grams_of_carbs": {
              "type": "integer",
              "description": "Amount of carbohydrates in grams."
            },
            "grams_of_fat": {
              "type": "integer",
              "description": "Amount of fat in grams."
            },
            "grams_of_protein": {
              "type": "integer",
              "description": "Amount of protein in grams."
            },
            "calories": {
              "type": "integer",
              "description": "Total calories contained in the item."
            }
          },
          "required": [
            "description",
            "grams_of_carbs",
            "grams_of_fat",
            "grams_of_protein",
            "calories"
          ],
          "additionalProperties": false
        }
      },
      "total_grams_of_carbs": {
        "type": "integer",
        "description": "Total grams of carbohydrates for all items."
      },
      "total_grams_of_fat": {
        "type": "integer",
        "description": "Total grams of fat for all items."
      },
      "total_grams_of_protein": {
        "type": "integer",
        "description": "Total grams of protein for all items."
      },
      "total_calories": {
        "type": "integer",
        "description": "Total calories for all items."
      }
    },
    "required": [
      "rationale",
      "items",
      "total_grams_of_carbs",
      "total_grams_of_fat",
      "total_grams_of_protein",
      "total_calories"
    ],
    "additionalProperties": false
  },
  "strict": true
}'

ap c.generate!
