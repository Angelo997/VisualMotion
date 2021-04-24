package it.uniba.di.application;

import javax.swing.SwingUtilities;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.BorderFactory;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.Shape;
import java.awt.Stroke;
import java.awt.Toolkit;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseMotionListener;
import java.awt.geom.Ellipse2D;
import java.awt.event.MouseMotionAdapter;
import java.util.TreeMap;





public class Visual extends JPanel {
	
	private double width; 
	private double height;
	private int n_host;		
	private TreeMap<Integer,host> hosts = new TreeMap<Integer,host>();
	
	public static void main(String[] args) {
	    JFrame window;
	    window = new JFrame("host");  // The parameter shows in the window title bar.
	    
	    Visual panel = new Visual(8,500,500); // The drawing area.
	    window.getContentPane().add( panel ); // Show the panel in the window.
	    window.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE); // End program when window closes.
	    window.pack();  // Set window size based on the preferred sizes of its contents.
	    window.setResizable(false); // Don't let user resize window.
	    Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
	    window.setLocation( // Center window on screen.
	            (screen.width - window.getWidth())/2, 
	            (screen.height - window.getHeight())/2 );
	    panel.requestFocusInWindow();  // make sure key events go to the panel.
	    window.setVisible(true); // Open the window, making it visible on the screen.
	}
	    
	
	Visual(int n,int w,int h){
		
		n_host = n;
		//center of the canvas
		double xcenter  = (w/2);
		double ycenter = (h/2);
		
		setPreferredSize( new Dimension(w,h));
		
		double r = Math.min(w,h)/2;
		double d = r/5;
		r = r - d/2 - 10;
		
		for(int i = 0; i < n_host; i++) { // number vertex is the number of host
		    double x = xcenter - (r * Math.cos(2 * Math.PI * i / n_host)) - d/2;
			double y = ycenter - (r * Math.sin(2 * Math.PI * i / n_host)) - d/2;
			hosts.put(i, new host(i,x,y,d));

	  }
	}
	
	class host {
		int id;
		double x;
		double y;
		double dim;
    	Color c = Color.BLACK;
		host(int i,double x,double y,double d){
			this.x = x;
			this.y = y;
			id = i;
			dim = d;
			Color c = Color.BLACK;
		}
		
		int getid(){
			return  id;
		}
		
		void setColor(Color n) {
	       	c = n;
	    }
		
	   void paint(Graphics2D g2) {
		   
		    g2.setPaint(Color.WHITE);
	        g2.fill( new Ellipse2D.Double(x,y,dim,dim) );
		    g2.setPaint(Color.BLACK);
		    g2.draw( new Ellipse2D.Double(x,y,dim,dim) );
		    
	        
	        g2.setPaint(Color.BLACK);
	        drawCenteredString(g2,Integer.toString(id),new Ellipse2D.Double(x,y,dim,dim) , g2.getFont());    
	   }
	   /**
	    * Draw a String centered in the middle of a Rectangle.
	    *
	    * @param g The Graphics instance.
	    * @param text The String to draw.
	    * @param rect The Rectangle to center the text in.
	    */

	   public void drawCenteredString(Graphics g, String text, Shape s, Font font) {
	       // Get the FontMetrics
	   	   Rectangle rect = s.getBounds();
	       FontMetrics metrics = g.getFontMetrics(font);
	       // Determine the X coordinate for the text
	       int x = rect.x + (rect.width - metrics.stringWidth(text)) / 2;
	       // Determine the Y coordinate for the text (note we add the ascent, as in java 2d 0 is top of the screen)
	       int y = rect.y + ((rect.height - metrics.getHeight()) / 2) + metrics.getAscent();
	       // Set the font
	       g.setFont(font);
	       // Draw the String
	       g.drawString(text, x, y);
	   }
		
	}
	
   protected void paintComponent(Graphics g) {
	   super.paintComponent(g);
	   
	   Graphics2D g2 = (Graphics2D)g;
	   
	   //abilita antialiasing
	   g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
			   RenderingHints.VALUE_ANTIALIAS_ON);
	   
	 
	   g2.setPaint(Color.WHITE);
	   g2.fill(new Rectangle(0, 0,getWidth()-1,getHeight()-1));
	   
	   for (int i = 0; i < n_host; i++) {
		   hosts.get(i).paint(g2);
	   }
	   g2.setPaint(Color.BLACK);
	   g2.draw(new Rectangle(0, 0,getWidth()-1,getHeight()-1));
   }
 
	    
}

