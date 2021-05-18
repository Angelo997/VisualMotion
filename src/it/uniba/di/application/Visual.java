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
import java.awt.GradientPaint;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RadialGradientPaint;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.Shape;
import java.awt.Stroke;
import java.awt.Toolkit;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseMotionListener;
import java.awt.geom.AffineTransform;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Line2D;
import java.awt.geom.Path2D;
import java.awt.geom.Point2D;
import java.awt.geom.Rectangle2D;
import java.awt.geom.Point2D.Double;
import java.awt.image.BufferedImage;
import java.awt.event.MouseMotionAdapter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.concurrent.ThreadLocalRandom;

import it.uniba.di.parser.AODVParser;
import it.uniba.di.support.structures.ConnectivityMatrix;


public class Visual extends JPanel {
	private double width; 
	private double height;
	
	private int n_host = 0;
	private HashMap<Integer,host> hosts; //tempo di ritrovamento degli elementi costante


	private ConnectivityMatrix<Boolean> link;
	private BufferedImage OSC;  // Stores a copy of the panel content.
	private Graphics2D OSG;     // Graphics context for drawing to OSC/
	
	public static void main(String[] args) {
	    JFrame window;
	    window = new JFrame("host");  // The parameter shows in the window title bar.
	    
	    Visual panel = new Visual(500,500); // The drawing area.
	    window.getContentPane().add( panel ); // Show the panel in the window.
	    window.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE); // End program when window closes.
	    window.pack();  // Set window size based on the preferred sizes of its contents.
	    window.setResizable(false); // Don't let user resize window.
	    Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
	    window.setLocation( // Center window on screen.
	            (screen.width - window.getWidth())/2, 
	            (screen.height - window.getHeight())/2 );
	    panel.requestFocusInWindow();  // make sure key events go to the panel.
	    panel.setNumberHost(6);
	    window.setVisible(true); // Open the window, making it visible on the screen.
	    panel.repaint();
	}
	    
	
	Visual(int w,int h){
		setPreferredSize( new Dimension(w,h));
		OSC = new BufferedImage(w,h,BufferedImage.TYPE_4BYTE_ABGR);
	    OSG = OSC.createGraphics();
	    OSG.setBackground(new Color(0,0,0,0));
        OSG.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
		//center of the canvas
		
		width = w;
		height = h;
		
	}
	
	public void setNumberHost(int n){
		n_host = n;
		hosts = new HashMap(n); //imposta la capacità iniziale a n e il loadfactor (percentuale prima di reallocare la memoria) al 75%
		/*
		ConnectivityMatrix<Boolean> link = new ConnectivityMatrix<Boolean>(
					Boolean.class, n_host, false, false);
					*/
		double r = Math.min(width,height)/2;
		double d = 30;
		r = r - d/2 - 5;
		double xcenter  = (width/2);
		double ycenter = (height/2);
		for(int i = 0; i < n_host; i++) { // number vertex is the number of host
		    double x = xcenter - (r * Math.cos(2 * Math.PI * i / n_host)) - d/2;
			double y = ycenter - (r * Math.sin(2 * Math.PI * i / n_host)) - d/2;
			hosts.put(i, new host(i,x,y,d));
			

	  }
	}
	

	
	static class host {
		private int id;
		boolean lit_up;
		private double x;
		private double y;
		private static double dim;
    	Color c = Color.BLACK;
		host(int i,double x,double y,double d){
			this.x = x;
			this.y = y;
			id = i;
			dim =  d;
			Color c = Color.BLACK;
			lit_up = false;
		}
		static double getDim() {
			return dim;
		}
		
		int getid(){
			return  id;
		}
		
		void setColor(Color n) {
	       	c = n;
	    }
		double getX() {
			return x;
		}
		double getY() {
			return y;
		}
		
	   public void turn_on() {lit_up = true;}
	   private void turn_off() {lit_up = false;}
	   protected void light_up(Graphics2D g2) {
		   Color yellow_t = new Color(255,255,0,100);
		   Color t_green = new Color (0,255,0,150);
		   Color t_green2 = new Color (0,255,0,255);
		 
		   
		   Point2D center = new Point2D.Double((x + dim/2),(y + dim/2));
		     float radius = (float) dim/2;
		     float[] dist = {0.3f, 0.9f, 1.0f};
		     Color[] colors = {yellow_t,t_green, t_green2};
		     RadialGradientPaint p =
		         new RadialGradientPaint(center, radius, dist, colors);

		   g2.setPaint(p);
		   g2.fill( new Ellipse2D.Double(x,y,dim,dim));
		  
	   }
		
	   void paint(Graphics2D g2) {
		   
		    //g2.setPaint(Color.WHITE);
	        //g2.fill( new Ellipse2D.Double(x,y,dim,dim));
		    
	        
	        if(lit_up) {
	        	light_up(g2);
	        	turn_off();
	        }
	        
	        g2.setPaint(Color.BLACK);
		    g2.draw( new Ellipse2D.Double(x,y,dim,dim));
		   		    
	        //MODIFICARE IL FONT DEI NUMERI ALL'INTERNO DEGLI HOST
	        g2.setPaint(Color.BLACK);
	        drawCenteredString(g2,Integer.toString(id + 1),new Ellipse2D.Double(x,y,dim,dim) , g2.getFont());
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
	
	/*Questa scelta è stata fatta per non permettere di disegnare i link
	 * al di fuori della funzione paint component*/
	public void loadLink (ConnectivityMatrix<Boolean> cm) {
		   link = cm; //va fatta la deep copy
	 }

	
	public void reset_color (Graphics g) {
		Graphics2D g2 = (Graphics2D) g;
		 g2.setPaint(Color.BLACK);
	}

	private void drawLink(Graphics g) {
		   Graphics2D g2 = (Graphics2D)g;
		   double x;
		   double y;
		   Point2D p;
		   Point2D c;
		   
		   double d = host.dim;
		   g2.setPaint(Color.BLACK);
		 //aggiungere un controllo se link è null
		   
		   for (int i = 0; i < n_host; i++) {
			   x = (hosts.get(i).getX() + d/2);
			   y = (hosts.get(i).getY() + d/2);
				for (int j = i + 1; j < n_host && j != i; j++) {
					if(link.get(i,j)) {
						p = new Point2D.Double(x,y);
						c = new Point2D.Double((hosts.get(j).getX() + d/2),(hosts.get(j).getY() + d/2));
						quadto(p,c);
					    g2.draw( new Line2D.Double(p,c));
					}
				}
			}
	 }
	
	public void drawConnection(int start,int end,Color c) {
		Graphics2D g2 = OSG;
		double x1;
		double y1;
		double x2;
		double y2;
		Point2D from;
		Point2D to;
		double d = host.dim;	
		g2.setPaint(c);		
				x1 = hosts.get(start).getX();
				y1 = hosts.get(start).getY();
				x2 = hosts.get(end).getX();
				y2 = hosts.get(end).getY();
					from = new Point2D.Double(x1 + d/2 ,y1 + d/2);
					to = new Point2D.Double(x2 + d/2, y2 + d/2);				
					quadto(from,to);
					//disegna la linea
					g2.setStroke(new BasicStroke(2.0f)); // g2 is an instance of Graphics2D
					drawArrowLine(g2,from.getX(),from.getY(),to.getX(),to.getY(),15,7,c);
				    g2.setStroke(new BasicStroke(1)); //reimposta lo spessore della linea a 1
					reset_color(g2);
	
}
	public void lightsHost(int start,int end) {
		Graphics2D g2 = OSG;
		hosts.get(start).turn_on();
	    hosts.get(end).turn_on();
	    reset_color(g2);
		
	}
	

	/**
	 * Draw an arrow line between two points.
	 * @param g the graphics component.
	 * @param x1 x-position of first point.
	 * @param y1 y-position of first point.
	 * @param x2 x-position of second point.
	 * @param y2 y-position of second point.
	 * @param d  the width of the arrow.
	 * @param h  the height of the arrow.
	 */
	private void drawArrowLine(Graphics g, double x1, double y1, double x2, double y2, double d, double h,Color c) {
		Graphics2D g2 = (Graphics2D) g;
		Path2D.Double p = new Path2D.Double();
	    double dx = x2 - x1, dy = y2 - y1;
	    double D = Math.sqrt(dx*dx + dy*dy);
	    double xm = D - d, xn = xm, ym = h, yn = -h, x;
	    double sin = dy / D, cos = dx / D;

	    x = xm*cos - ym*sin + x1;
	    ym = xm*sin + ym*cos + y1;
	    xm = x;

	    x = xn*cos - yn*sin + x1;
	    yn = xn*sin + yn*cos + y1;
	    xn = x;
	    p.moveTo(x2,y2);
	    p.lineTo(xm,ym);
	    p.lineTo(xn,yn);
	    p.closePath();
	   
	    g2.draw(new Line2D.Double(x1,y1,x2,y2));
	    g2.fill(p);
	    g2.setPaint(Color.BLACK);
	    g2.setStroke(new BasicStroke(1));
	    g2.draw(p);
	    g2.setPaint(c);
	    g2.setStroke(new BasicStroke(2.0f));
	  
	}
	
	//elimina i tratti dei segmenti di connessione che attraversano l'host
	private void quadto(Point2D c,Point2D p) {
		double coeff = Math.abs((p.getY() - c.getY())/(p.getX() - c.getX()));
		double a = Math.atan(coeff);
		double xc = c.getX();
		double yc = c.getY();
		double dim = host.getDim()/2;
		double xa = dim * Math.cos(a);
		double ya =  dim * Math.sin(a);
		
		if(p.getX() < xc && p.getY()< yc) {
			   p.setLocation(p.getX() + xa, p.getY() + ya);
			   c.setLocation(c.getX() - xa, c.getY() - ya);
			   
		}else if(p.getX() < xc && p.getY()> yc) {
			   p.setLocation(p.getX() + xa, p.getY() - ya);
			   c.setLocation(c.getX() - xa, c.getY() + ya);

		}else if(p.getX() > xc && p.getY()< yc) {
				p.setLocation(p.getX() - xa, p.getY() + ya);
				c.setLocation(c.getX() + xa, c.getY() - ya);
				
		}else if (p.getX() > xc && p.getY()> yc) {
				p.setLocation(p.getX() - xa, p.getY() - ya);
				c.setLocation(c.getX() + xa, c.getY() + ya);
				
		}
		
		if (p.getX() == xc) {
			if(p.getY() < yc) {
			   p.setLocation(p.getX(), p.getY() + dim);
			   c.setLocation(c.getX(), c.getY() - dim);
			}else {
			   p.setLocation(p.getX() , p.getY() - dim);
			   c.setLocation(c.getX(), c.getY() + dim);
		 }
		}
		if(p.getY() == yc) {
			if(p.getX() < xc) {
			   p.setLocation(p.getX() + dim, p.getY()  );
			   c.setLocation(c.getX() - dim, c.getY()  );
			}else {
			   p.setLocation(p.getX() - dim, p.getY());
			   c.setLocation(c.getX() + dim, c.getY()  );

			}
		}
	}
	

   protected void paintComponent(Graphics g) {
	   super.paintComponent(g);
	  
	   Graphics2D g2 = (Graphics2D)g;
	   
	   //abilità antialiasing
	   g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
			   RenderingHints.VALUE_ANTIALIAS_ON);
	   
	   g2.setPaint(Color.WHITE);
	   g2.fillRect(0, 0,getWidth()-1,getHeight()-1);
	
	   if(link != null) {drawLink(g);};

	   g2.setPaint(Color.BLACK);
	   g2.draw(new Rectangle(0, 0,getWidth()-1,getHeight()-1));
	   
   
	   g.drawImage(OSC,0,0,null);
	   Graphics2D g3 = (Graphics2D)g.create();
	   
	   OSG.clearRect(0, 0,getWidth()-1,getHeight()-1);
	   for (int i = 0; i < n_host; i++) {
		   hosts.get(i).paint(g2);
	   }
	   
   }
   

 
	    
}

