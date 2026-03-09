# BÁO CÁO: DỰ ĐOÁN GIÁ XE Ô TÔ CŨ BẰNG MÔ HÌNH HỒI QUY TUYẾN TÍNH

**MSSV:** 4551190011  
**Họ và tên:** Trần Anh Đại

---

## I. Giới thiệu

Bài báo cáo trình bày quá trình xây dựng mô hình **Hồi quy tuyến tính (Linear Regression)** kết hợp **biến đổi logarithm** để dự đoán giá xe ô tô cũ. Dữ liệu được lấy từ tập `car_data.csv` gồm **8.128 mẫu xe** với **13 đặc trưng**, giá gốc tính bằng đồng Rupee Ấn Độ (INR) và được quy đổi sang Việt Nam Đồng (VND) theo tỷ giá 1 INR ≈ 300 VND.

**Mục tiêu:** Dự đoán biến mục tiêu `selling_price` (giá bán xe cũ) dựa trên các thông số kỹ thuật và thông tin xe.

---

## II. Cài đặt

### 2.1. Thư viện sử dụng

```python
import numpy as np
import pandas as pd
import re
import warnings
warnings.filterwarnings('ignore')

import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error
```

Các thư viện chính:

| Thư viện | Mục đích |
|---|---|
| `numpy`, `pandas` | Xử lý dữ liệu số và dạng bảng |
| `matplotlib`, `seaborn` | Trực quan hóa dữ liệu |
| `sklearn` | Xây dựng mô hình, chia dữ liệu, chuẩn hóa, đánh giá |
| `re` | Xử lý chuỗi bằng biểu thức chính quy (regex) |

---

### 2.2. Đọc dữ liệu

```python
data = pd.read_csv("car_data.csv")

# Chuyển đổi giá từ INR sang VND
TY_GIA_INR_VND = 300
data["selling_price"] = data["selling_price"] * TY_GIA_INR_VND
```

Tập dữ liệu gốc gồm **8.128 dòng** và **13 cột**:

| Cột | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `name` | string | Tên đầy đủ của xe |
| `year` | int | Năm sản xuất |
| `selling_price` | int | Giá bán (đã quy đổi VND) |
| `km_driven` | int | Số km đã đi |
| `fuel` | string | Loại nhiên liệu (Diesel, Petrol, CNG, LPG) |
| `seller_type` | string | Loại người bán (Individual, Dealer, Trustmark Dealer) |
| `transmission` | string | Hộp số (Manual, Automatic) |
| `owner` | string | Số đời chủ sở hữu |
| `mileage` | string | Mức tiêu thụ nhiên liệu (kmpl / km/kg) |
| `engine` | string | Dung tích động cơ (CC) |
| `max_power` | string | Công suất tối đa (bhp) |
| `torque` | string | Mô-men xoắn (Nm / kgm) |
| `seats` | float | Số chỗ ngồi |

---

### 2.3. Khám phá dữ liệu (EDA)

Các bước khám phá đã thực hiện:

1. **Kiểm tra giá trị thiếu:** Sử dụng `data.isnull().sum()` để xác định các cột có giá trị null.
2. **Kiểm tra thông tin dữ liệu:** Sử dụng `data.info()` để xem kiểu dữ liệu và số lượng non-null mỗi cột.
3. **Phân bố giá xe:** Vẽ biểu đồ histogram so sánh phân bố giá xe gốc và phân bố sau biến đổi logarithm.

```python
# Phân bố giá xe: gốc vs log
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
axes[0].hist(data['selling_price'], bins=50, color='#3498db', edgecolor='white')
axes[0].set_title('Phân bố giá xe (gốc)')
axes[1].hist(np.log1p(data['selling_price']), bins=50, color='#e74c3c', edgecolor='white')
axes[1].set_title('Phân bố log(giá xe)')
plt.tight_layout()
plt.show()
```

**Nhận xét:** Phân bố giá xe gốc bị lệch phải (right-skewed) rất mạnh — đa số xe có giá thấp, một số ít có giá rất cao. Sau khi áp dụng biến đổi `log1p`, phân bố trở nên gần dạng chuẩn (normal distribution) hơn, phù hợp hơn cho mô hình hồi quy tuyến tính.

---

### 2.4. Tiền xử lý dữ liệu

#### a) Trích xuất thông tin & Làm sạch dữ liệu

```python
df = data.copy()
df = df.dropna()

# Trích xuất tên hãng xe từ cột name
df['brand'] = df['name'].apply(lambda x: x.split(' ')[0])

# Gộp hãng xe hiếm (< 50 xe) thành "Other"
brand_counts = df['brand'].value_counts()
rare_brands = brand_counts[brand_counts < 50].index
df['brand'] = df['brand'].apply(lambda x: 'Other' if x in rare_brands else x)

# Tính tuổi xe
df['car_age'] = 2024 - df['year']
```

- **Xóa dòng null:** Loại bỏ các dòng có giá trị thiếu.
- **Trích xuất hãng xe:** Lấy từ đầu tiên trong cột `name` làm tên hãng. Các hãng có ít hơn 50 mẫu được gộp thành nhóm "Other".
- **Tạo đặc trưng `car_age`:** Tuổi xe = 2024 − năm sản xuất.

#### b) Làm sạch cột số dạng chuỗi

```python
df['mileage'] = df['mileage'].str.replace(' kmpl', '').str.replace(' km/kg', '').astype(float)
df['engine'] = df['engine'].str.replace(' CC', '').astype(float)
df['max_power'] = df['max_power'].str.replace(' bhp', '').replace('', np.nan)
df = df.dropna(subset=['max_power'])
df['max_power'] = df['max_power'].astype(float)
```

Các cột `mileage`, `engine`, `max_power` ban đầu là kiểu chuỗi có kèm đơn vị (kmpl, CC, bhp). Code thực hiện loại bỏ đơn vị và chuyển sang kiểu số thực (`float`).

#### c) Xử lý cột `torque`

```python
def parse_torque(torque_str):
    if pd.isna(torque_str) or str(torque_str).strip() == '':
        return np.nan
    s = str(torque_str).lower().strip()
    is_kgm = 'kgm' in s
    s = re.split(r'[@at]', s)[0]
    s = s.replace('nm', '').replace('kgm', '').replace(',', '').strip()
    match = re.search(r'[\d.]+', s)
    if match:
        val = float(match.group())
        return val * 9.8067 if is_kgm else val
    return np.nan

df['torque_nm'] = df['torque'].apply(parse_torque)
df['torque_nm'] = df['torque_nm'].fillna(df['torque_nm'].median())
```

Cột `torque` có định dạng rất không thống nhất (có thể là Nm hoặc kgm, kèm thông tin vòng tua RPM). Hàm `parse_torque` thực hiện:
- Tách phần giá trị trước ký tự `@` hoặc `at`.
- Chuyển đổi từ kgm sang Nm (nhân 9.8067).
- Điền giá trị trung vị (median) cho các giá trị không parse được.

#### d) Loại bỏ Outliers bằng IQR

```python
for col in ['selling_price', 'km_driven']:
    Q1 = df[col].quantile(0.25)
    Q3 = df[col].quantile(0.75)
    IQR = Q3 - Q1
    df = df[(df[col] >= Q1 - 1.5 * IQR) & (df[col] <= Q3 + 1.5 * IQR)]
```

Áp dụng phương pháp **IQR (Interquartile Range)** để loại bỏ các giá trị ngoại lai trên 2 cột `selling_price` và `km_driven`. Các giá trị nằm ngoài khoảng $[Q_1 - 1.5 \times IQR,\ Q_3 + 1.5 \times IQR]$ sẽ bị loại.

---

### 2.5. Encoding & Chọn Features

```python
y = df['selling_price']

# One-Hot Encoding cho biến phân loại
df_encoded = pd.get_dummies(df, columns=['fuel', 'seller_type', 'owner', 'brand'], drop_first=True)
df_encoded['transmission'] = df_encoded['transmission'].map({'Manual': 0, 'Automatic': 1})

# Loại bỏ các cột không cần thiết
X = df_encoded.drop(columns=['name', 'year', 'selling_price', 'torque'], errors='ignore')
```

- **Biến mục tiêu:** `selling_price`
- **One-Hot Encoding:** Áp dụng cho các cột phân loại `fuel`, `seller_type`, `owner`, `brand` (sử dụng `drop_first=True` để tránh đa cộng tuyến).
- **Label Encoding:** Cột `transmission` được mã hóa thủ công (Manual = 0, Automatic = 1).
- **Loại bỏ:** Các cột `name`, `year`, `selling_price`, `torque` (đã có `car_age` thay cho `year`, đã có `torque_nm` thay cho `torque`).

**Ma trận tương quan** được vẽ cho các biến số để xem mối quan hệ giữa các đặc trưng với biến mục tiêu:

```python
num_cols = ['car_age', 'km_driven', 'mileage', 'engine', 'max_power', 'torque_nm', 'seats', 'selling_price']
sns.heatmap(df_encoded[num_cols].corr(), annot=True, fmt='.2f', cmap='RdBu_r', center=0, square=True)
```

---

### 2.6. Chia tập Train/Test & Chuẩn hóa

```python
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Biến đổi logarit cho biến mục tiêu
y_train_log = np.log1p(y_train)
y_test_log = np.log1p(y_test)
```

| Thông số | Giá trị |
|---|---|
| Tỷ lệ chia | 80% Train – 20% Test |
| Random state | 42 |
| Chuẩn hóa | StandardScaler (z-score: $z = \frac{x - \mu}{\sigma}$) |
| Biến đổi biến mục tiêu | `log1p(y)` = $\ln(1 + y)$ |

**Lý do dùng `log1p`:** Biến mục tiêu `selling_price` có phân bố lệch phải mạnh. Biến đổi logarithm giúp giảm skewness, đưa phân bố về gần dạng chuẩn, cải thiện hiệu suất mô hình hồi quy tuyến tính.

---

### 2.7. Xây dựng & Huấn luyện mô hình

```python
lr = LinearRegression()
lr.fit(X_train_scaled, y_train_log)

# Dự đoán trên tập test (chuyển ngược từ log về giá trị gốc)
y_pred_log = lr.predict(X_test_scaled)
y_pred = np.expm1(y_pred_log)
```

**Mô hình:** Linear Regression + Log Transform

| Thành phần | Chi tiết |
|---|---|
| Mô hình | Linear Regression (`sklearn.linear_model.LinearRegression`) |
| Kỹ thuật | $\log(1 + y) = w_0 + w_1 x_1 + w_2 x_2 + \ldots + w_n x_n$ |
| Dự đoán | Chuyển ngược bằng `expm1`: $\hat{y} = e^{\hat{y}_{log}} - 1$ |
| Ý nghĩa | Hồi quy tuyến tính trên không gian logarithm, giúp mô hình xử lý tốt hơn dữ liệu có phân bố lệch |

---

### 2.8. Đánh giá mô hình

```python
r2 = r2_score(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))
mae = mean_absolute_error(y_test, y_pred)

# Cross-Validation 5-fold
cv_scores = cross_val_score(LinearRegression(), X_train_scaled, y_train_log, cv=5, scoring='r2')
```

Các chỉ số đánh giá được sử dụng:

| Chỉ số | Công thức | Ý nghĩa |
|---|---|---|
| $R^2$ (Hệ số xác định) | $R^2 = 1 - \frac{\sum(y_i - \hat{y}_i)^2}{\sum(y_i - \bar{y})^2}$ | Mức độ dữ liệu phù hợp với mô hình. Gần 1 = tốt |
| RMSE | $\sqrt{\frac{1}{n}\sum(y_i - \hat{y}_i)^2}$ | Sai số trung bình (nhạy với outliers) |
| MAE | $\frac{1}{n}\sum\|y_i - \hat{y}_i\|$ | Sai số tuyệt đối trung bình |
| Cross-Validation | R² trên 5 fold | Đánh giá độ ổn định, tránh overfitting |

---

### 2.9. Trực quan hóa kết quả

Code thực hiện 3 biểu đồ chính:

#### a) Giá thực tế vs Giá dự đoán (Scatter plot)

```python
plt.scatter(y_test, y_pred, alpha=0.3, color='steelblue')
plt.plot([min_val, max_val], [min_val, max_val], 'r--', label='Dự đoán hoàn hảo')
```

Biểu đồ scatter so sánh giá thực tế (trục X) và giá dự đoán (trục Y). Đường chéo đỏ nét đứt biểu thị dự đoán hoàn hảo — các điểm càng nằm sát đường này, mô hình càng chính xác.

#### b) Phân tích phần dư (Residuals)

```python
residuals = y_test - y_pred
# Phần dư vs Giá dự đoán + Histogram phần dư
```

- **Biểu đồ phần dư vs giá dự đoán:** Kiểm tra giả định tính đồng nhất của phương sai (homoscedasticity). Nếu phần dư phân bố đều quanh trục 0, mô hình hoạt động tốt.
- **Histogram phần dư:** Kiểm tra phần dư có phân bố chuẩn hay không.

#### c) Top 10 đặc trưng quan trọng nhất

```python
feature_importance = pd.DataFrame({
    'Feature': X.columns,
    'Coefficient': lr.coef_
})
feature_importance['Abs_Coefficient'] = feature_importance['Coefficient'].abs()
feature_importance = feature_importance.sort_values('Abs_Coefficient', ascending=False).head(10)
```

Biểu đồ thanh ngang hiển thị top 10 đặc trưng có hệ số hồi quy (coefficient) lớn nhất theo giá trị tuyệt đối. Hệ số dương (xanh) cho thấy đặc trưng làm tăng giá, hệ số âm (đỏ) cho thấy đặc trưng làm giảm giá.

---

## III. Kết quả

### 3.1. Bảng so sánh kết quả

Mô hình được xây dựng trong notebook là **Linear Regression + Log Transform** trên biến mục tiêu:

| Mô hình | Kỹ thuật | R² (Test) | Cross-Validation R² |
|---|---|---|---|
| Linear Regression + Log Transform | $\log(1+y) = w_0 + \sum w_i x_i$ | ~0.81 | ~0.87 ± 0.008 |

### 3.2. Các chỉ số đánh giá

| Chỉ số | Giá trị | Ý nghĩa |
|---|---|---|
| **R²** | ≈ 0.81 | Mô hình giải thích được khoảng 81% sự biến đổi của giá xe |
| **RMSE** | ≈ 108,253 VND | Sai số bình phương trung bình — nhạy với các dự đoán sai nhiều |
| **MAE** | ≈ 78,089 VND | Sai số tuyệt đối trung bình — phản ánh sai số "điển hình" |
| **CV R² (5-fold)** | ≈ 0.8723 ± 0.008 | Mô hình ổn định, không overfitting nghiêm trọng |

**Lưu ý:** MAE < RMSE cho thấy có một số mẫu bị dự đoán sai nhiều (outliers trong sai số), khiến RMSE bị đẩy lên cao hơn.

### 3.3. Nhận xét

1. **Hiệu quả của biến đổi Log:** Áp dụng `log1p` cho biến mục tiêu `selling_price` giúp cải thiện đáng kể hiệu suất mô hình so với hồi quy trên giá gốc. Lý do là phân bố giá xe bị lệch phải rất mạnh — biến đổi log giúp "kéo" phân bố về gần dạng chuẩn.

2. **Cross-Validation cho thấy mô hình ổn định:** R² trung bình qua 5 fold đạt ≈ 0.8723 với độ lệch chuẩn chỉ 0.008, cho thấy mô hình không bị overfitting và hoạt động nhất quán trên các phần dữ liệu khác nhau.

3. **Các yếu tố ảnh hưởng mạnh nhất đến giá xe cũ:**
   - **`max_power`** (công suất động cơ): Tương quan dương mạnh nhất — xe công suất cao thường có giá cao hơn.
   - **`car_age`** (tuổi xe): Tương quan âm mạnh — xe càng cũ, giá càng thấp.
   - **`engine`** (dung tích động cơ): Tương quan dương đáng kể.
   - **`brand`** (hãng xe): Các hãng xe khác nhau ảnh hưởng lớn đến mức giá.

4. **Hạn chế của mô hình:**
   - Mô hình hồi quy tuyến tính giả định mối quan hệ **tuyến tính** giữa các biến. Trong thực tế, mối quan hệ giữa giá xe và các đặc trưng có thể **phi tuyến**.
   - Một số dự đoán có sai số lớn (thể hiện qua RMSE > MAE), cho thấy mô hình chưa xử lý tốt các trường hợp đặc biệt.
   - Để cải thiện, có thể thử nghiệm các mô hình phi tuyến như **Random Forest**, **XGBoost**, hoặc **Neural Network**.

---

## IV. Kết luận

Bài báo cáo đã trình bày quá trình xây dựng hệ thống dự đoán giá xe ô tô cũ bằng mô hình hồi quy tuyến tính kết hợp biến đổi logarithm. Tóm tắt kết quả:

- **Mô hình Linear Regression + Log Transform** đạt $R^2 \approx 0.81$ trên tập test, nghĩa là giải thích được khoảng 81% sự biến đổi của giá xe.
- **Kỹ thuật biến đổi `log1p`** cho biến mục tiêu giúp cải thiện đáng kể kết quả khi phân bố giá xe bị lệch mạnh.
- **Chuẩn hóa StandardScaler** giúp đưa các đặc trưng về cùng thang đo, cải thiện quá trình tối ưu hóa.
- **Cross-Validation 5-fold** (R² ≈ 0.87 ± 0.008) xác nhận mô hình ổn định và không overfitting.
- Các yếu tố kỹ thuật như **công suất động cơ (`max_power`)**, **tuổi xe (`car_age`)** và **dung tích động cơ (`engine`)** là những đặc trưng ảnh hưởng mạnh nhất đến giá bán xe cũ.

Hệ thống dự đoán giá xe cũ này có tiềm năng ứng dụng thực tế, hỗ trợ cả người mua lẫn người bán trong việc định giá xe một cách hợp lý. Để nâng cao hơn nữa, hướng phát triển tiếp theo có thể bao gồm: sử dụng các mô hình ensemble (Random Forest, Gradient Boosting), thêm đặc trưng mới (tình trạng xe, vị trí địa lý), hoặc áp dụng kỹ thuật feature engineering nâng cao hơn.
