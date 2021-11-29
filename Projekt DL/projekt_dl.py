import streamlit as st
import pandas as pd
import numpy as np
import os
import cv2
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import datetime
from PIL import Image
st.set_page_config(page_title="WDevs",initial_sidebar_state="expanded")
st.caption('*Klasyfikacja jabłek* :sunglasses: by WDevs, 2021')
st.sidebar.title('Witaj w sortowni jabłek Wdevsów!')
class_names= ['Cortland', 'Gloster', 'Gala', 'Granny Smith', 'Lobo', 'Golden delicious']
file = st.sidebar.file_uploader("Wybierz swoje jabłka", type=["png", "jpg", "jpeg"], accept_multiple_files=False)
if file is not None:
    image = Image.open(file)
    try:
      new_model = tf.keras.models.load_model('model.h5')
    except OSError:
      "Nie mogę wczytać modelu..."
    else:
      img_array = np.array(image)
      img = tf.image.resize(img_array, size=(256,256))
      img = tf.expand_dims(img, axis=0)
      pred = new_model.predict(img)
      st.image(
        image,
        caption=f"Wczytane jabłka: {class_names[np.argmax(pred)]}",
        use_column_width=True,
    )