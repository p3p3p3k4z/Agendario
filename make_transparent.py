import os
from PIL import Image

def remove_white_background(img_path):
    try:
        img = Image.open(img_path).convert("RGBA")
        datas = img.getdata()

        newData = []
        for item in datas:
            # Change all white (also shades of white)
            # to transparent. Adjust tolerance if needed.
            # R, G, B, A
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)

        img.putdata(newData)
        img.save(img_path, "PNG")
        print(f"Processed: {img_path}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")

def main():
    stickers_dir = 'assets/stickers'
    if not os.path.exists(stickers_dir):
        print(f"Directory {stickers_dir} not found.")
        return

    for filename in os.listdir(stickers_dir):
        if filename.lower().endswith('.png'):
            file_path = os.path.join(stickers_dir, filename)
            remove_white_background(file_path)

if __name__ == "__main__":
    main()
