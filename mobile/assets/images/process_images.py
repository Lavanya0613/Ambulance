from PIL import Image
import math

def make_transparent(input_path, output_path, bg_color=(255, 255, 255), threshold=30):
    img = Image.open(input_path).convert('RGBA')
    data = img.getdata()
    new_data = []
    
    for item in data:
        r, g, b, a = item
        # Calculate distance from background color
        dist = math.sqrt((r - bg_color[0])**2 + (g - bg_color[1])**2 + (b - bg_color[2])**2)
        
        if dist < threshold:
            new_data.append((255, 255, 255, 0))
        elif dist < threshold + 30:
            # Alpha gradient for smooth edges
            alpha = int((dist - threshold) / 30 * 255)
            new_data.append((r, g, b, alpha))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, 'PNG')

print('Processing ambulance...')
make_transparent('realistic_ambulance_v2.jpg', 'ambulance_transparent.png', bg_color=(255, 255, 255), threshold=10)

print('Processing care plan box...')
# Hex #EAF8FC is (234, 248, 252)
make_transparent('care_plan_box_v2.jpg', 'care_plan_box_transparent.png', bg_color=(234, 248, 252), threshold=15)

print('Done!')
