# E-Commerce Database Management System

## 📌 Overview
This project is an **E-Commerce Database Management System** designed as part of the **Introduction to Databases (BIM302)** course at **Ege University, Faculty of Engineering, Computer Engineering Department**. The system models the structure of major e-commerce platforms like **Amazon, Hepsiburada, and Trendyol**, integrating key functionalities such as **user management, shop management, order processing, payment handling, product inventory, shopping experience, and logistics**.

## 📌 Enhanced Entity-Relationship Diagram
![Image](https://github.com/user-attachments/assets/6cb4b587-3245-4f05-af42-593fcd2ed56a)

## 🚀 Features
### 🔹 User & Customer Management
- Supports different **user types**: Customers and Shop Owners.
- Customers can be **regular or exclusive** members.
- Registered cards and billing information management.

### 🔹 Shop & Product Management
- Shop owners can **manage multiple shops**.
- Products are categorized with a **parent-child hierarchy**.
- Shops can **apply discounts** to products.

### 🔹 Order Processing & Payment
- Supports multiple **payment methods** (Cards, Gift Cards, HepsiPay).
- Integrated **shopping cart and wishlist** functionality.
- Coupon system for **discounted purchases**.

### 🔹 Logistics & Delivery
- Multiple **delivery options**: Home address, pickup points, and automated lockers.
- Real-time **order tracking** with logistics information.

### 🔹 Customer Interaction & Reviews
- Customers can **review products and shops**.
- Discussion system for **Q&A on products**.

### 🔹 Returns & Refunds
- Customers can **return specific items** within an order.
- Approved returns **update stock and shop income**.

## 📚 Database Design
The project follows a structured **database design methodology**, including:
1. **Conceptual Design**: Developed using **EER Diagrams** for different e-commerce platforms.
2. **Logical Design**: **Relational Model** conversion using a **9-step methodology**.
3. **Physical Design**: Implemented using **SQL DDL (Data Definition Language) statements**.

## 🛠️ Technologies Used
- **Database Management System**: PostgreSQL
- **SQL**: DDL (Create Tables, Constraints), DML (Insert, Update, Delete)
- **Triggers**: Automated logic for order handling, billing updates, and returns management.

## 🐛 Sample Database Triggers
- **User Authentication & Customer Type Management**
- **Shop Revenue Tracking & Stock Management**
- **Order Status Updates & Shipping Logistics**
- **Shopping Cart & Wishlist Operations**
- **Coupon Expiry & Discount Application**

## 📝 Installation & Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/mrdweeby/E-Commerce.git
   ```
2. Import the database schema:
   ```sql
   source SQL_Scripts/CreateTables.sql;
   ```
3. Import triggers:
   ```sql
   source SQL_Scripts/Triggers.sql;
   ```
4. Insert sample data:
   ```sql
   source SQL_Scripts/Populater.txt;
   ```


## 👨‍💻 Contributors
- **Bülent Yıldırım**  
- **Emir Kahraman**  
- **Alp Kutay Köksal**  
- **Tuğrul Akgül**  

📅 **Project Submission Date:** *17/01/2025*

