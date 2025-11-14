#!/usr/bin/env python3
"""
Pi-hole E-ink Display Script
Shows Pi-hole stats on e-ink display with animations
Updates every 10 minutes

Requirements:
    pip3 install requests pillow
    
For Waveshare e-ink displays:
    pip3 install waveshare-epd
"""

import time
import requests
import json
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Configuration
PIHOLE_API = "http://localhost/admin/api.php"
UPDATE_INTERVAL = 600  # 10 minutes in seconds
DISPLAY_WIDTH = 250    # Adjust for your display
DISPLAY_HEIGHT = 122   # Adjust for your display

# Try to import your specific e-ink display library
# Uncomment and modify based on your display
try:
    from waveshare_epd import epd2in13_V2  # Example for 2.13" Waveshare
    HAS_DISPLAY = True
    epd = epd2in13_V2.EPD()
except ImportError:
    print("No e-ink display library found, using image preview mode")
    HAS_DISPLAY = False

class PiholeDisplay:
    def __init__(self):
        self.font_large = None
        self.font_medium = None
        self.font_small = None
        self.load_fonts()
        
        if HAS_DISPLAY:
            self.init_display()
    
    def load_fonts(self):
        """Load fonts with fallbacks"""
        try:
            self.font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
            self.font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
            self.font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
        except:
            print("Using default fonts")
            self.font_large = ImageFont.load_default()
            self.font_medium = ImageFont.load_default()
            self.font_small = ImageFont.load_default()
    
    def init_display(self):
        """Initialize e-ink display"""
        try:
            print("Initializing e-ink display...")
            epd.init()
            epd.Clear(0xFF)
            print("Display initialized")
        except Exception as e:
            print(f"Display init error: {e}")
    
    def get_pihole_stats(self):
        """Fetch stats from Pi-hole API"""
        try:
            response = requests.get(PIHOLE_API, timeout=5)
            if response.status_code == 200:
                return response.json()
            else:
                print(f"API error: {response.status_code}")
                return None
        except Exception as e:
            print(f"Error fetching stats: {e}")
            return None
    
    def format_number(self, num):
        """Format large numbers (e.g., 1234567 -> 1.23M)"""
        try:
            num = int(num)
            if num >= 1_000_000:
                return f"{num/1_000_000:.2f}M"
            elif num >= 1_000:
                return f"{num/1_000:.1f}K"
            else:
                return str(num)
        except:
            return "0"
    
    def create_stats_image(self, stats):
        """Create image with Pi-hole stats"""
        # Create blank image
        image = Image.new('1', (DISPLAY_WIDTH, DISPLAY_HEIGHT), 255)  # 1-bit, white background
        draw = ImageDraw.Draw(image)
        
        if stats is None:
            draw.text((10, 50), "Pi-hole Offline", font=self.font_medium, fill=0)
            return image
        
        y_pos = 5
        
        # Title with time
        current_time = datetime.now().strftime("%H:%M")
        draw.text((5, y_pos), "Pi-hole Stats", font=self.font_medium, fill=0)
        draw.text((DISPLAY_WIDTH - 50, y_pos), current_time, font=self.font_small, fill=0)
        draw.line([(0, y_pos + 20), (DISPLAY_WIDTH, y_pos + 20)], fill=0, width=1)
        
        y_pos += 25
        
        # Stats
        queries_today = self.format_number(stats.get('dns_queries_today', 0))
        blocked_today = self.format_number(stats.get('ads_blocked_today', 0))
        percent_blocked = stats.get('ads_percentage_today', 0)
        domains_blocked = self.format_number(stats.get('domains_being_blocked', 0))
        
        # Queries
        draw.text((5, y_pos), f"Queries: {queries_today}", font=self.font_small, fill=0)
        y_pos += 18
        
        # Blocked
        draw.text((5, y_pos), f"Blocked: {blocked_today}", font=self.font_small, fill=0)
        y_pos += 18
        
        # Percentage (larger)
        percent_text = f"{percent_blocked:.1f}%"
        draw.text((5, y_pos), percent_text, font=self.font_large, fill=0)
        draw.text((80, y_pos + 5), "blocked", font=self.font_small, fill=0)
        y_pos += 30
        
        # Progress bar
        bar_width = DISPLAY_WIDTH - 20
        bar_height = 10
        bar_x = 10
        
        # Draw bar outline
        draw.rectangle([(bar_x, y_pos), (bar_x + bar_width, y_pos + bar_height)], 
                      outline=0, fill=255)
        
        # Fill bar based on percentage
        fill_width = int((bar_width - 2) * (float(percent_blocked) / 100))
        draw.rectangle([(bar_x + 1, y_pos + 1), 
                       (bar_x + 1 + fill_width, y_pos + bar_height - 1)], 
                      fill=0)
        
        y_pos += 15
        
        # Blocklist size
        draw.text((5, y_pos), f"Lists: {domains_blocked} domains", 
                 font=self.font_small, fill=0)
        
        return image
    
    def create_animation_frame(self, frame_num):
        """Create animation frame (loading/updating indicator)"""
        image = Image.new('1', (DISPLAY_WIDTH, DISPLAY_HEIGHT), 255)
        draw = ImageDraw.Draw(image)
        
        # Simple animation - rotating dots
        dots = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        dot = dots[frame_num % len(dots)]
        
        draw.text((DISPLAY_WIDTH // 2 - 30, DISPLAY_HEIGHT // 2 - 10), 
                 f"Updating {dot}", font=self.font_medium, fill=0)
        
        return image
    
    def display_image(self, image):
        """Display image on e-ink display"""
        if HAS_DISPLAY:
            try:
                # Rotate if needed for your display orientation
                # image = image.rotate(180)
                
                epd.display(epd.getbuffer(image))
                time.sleep(2)
            except Exception as e:
                print(f"Display error: {e}")
        else:
            # Preview mode - save to file
            image.save("/tmp/pihole-display.png")
            print("Image saved to /tmp/pihole-display.png")
    
    def show_animation(self, duration=2):
        """Show brief animation"""
        frames = 10
        for i in range(frames):
            frame = self.create_animation_frame(i)
            self.display_image(frame)
            time.sleep(duration / frames)
    
    def update_display(self):
        """Main update function"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Updating display...")
        
        # Optional: show loading animation
        # self.show_animation(duration=1)
        
        # Fetch and display stats
        stats = self.get_pihole_stats()
        image = self.create_stats_image(stats)
        self.display_image(image)
        
        if stats:
            print(f"  Queries: {stats.get('dns_queries_today', 0)}")
            print(f"  Blocked: {stats.get('ads_blocked_today', 0)} "
                  f"({stats.get('ads_percentage_today', 0):.1f}%)")
    
    def run(self):
        """Main loop"""
        print("Pi-hole Display Starting...")
        print(f"Update interval: {UPDATE_INTERVAL} seconds")
        print(f"Display size: {DISPLAY_WIDTH}x{DISPLAY_HEIGHT}")
        print("")
        
        try:
            while True:
                self.update_display()
                print(f"Next update in {UPDATE_INTERVAL} seconds...")
                print("")
                time.sleep(UPDATE_INTERVAL)
        except KeyboardInterrupt:
            print("\nStopping...")
            if HAS_DISPLAY:
                print("Clearing display...")
                epd.init()
                epd.Clear(0xFF)
                epd.sleep()
    
    def cleanup(self):
        """Cleanup display"""
        if HAS_DISPLAY:
            try:
                epd.sleep()
            except:
                pass

def main():
    display = PiholeDisplay()
    try:
        display.run()
    finally:
        display.cleanup()

if __name__ == "__main__":
    main()

