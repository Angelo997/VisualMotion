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
import java.awt.geom.AffineTransform;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Line2D;
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
	private HashMap<Integer,List<Integer>> success_ca; // = new TreeMap<Integer,host>();
	private HashMap<Integer,List<Integer>> fail_ca; // = new TreeMap<Integer,host>();
	private ConnectivityMatrix<Boolean> link;
	private Color color_ca = Color.BLACK;


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
		
		//center of the canvas
		setPreferredSize( new Dimension(w,h));
		width = w;
		height = h;
		
	}
	
	public void setNumberHost(int n){
		n_host = n;
		hosts = new HashMap(n); //imposta la capacit� iniziale a n e il loadfactor (percentuale prima di reallocare la memoria) al 75%
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
		repaint();	
	}
	

	
	static class host {
		private int id;
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
		
	   void paint(Graphics2D g2) {
		   
		    g2.setPaint(Color.WHITE);
	        g2.fill( new Ellipse2D.Double(x,y,dim,dim));
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
	
	/*Questa scelta � stata fatta per non permettere di disegnare i link
	 * al di fuori della funzione paint component*/
	public void loadLink (ConnectivityMatrix<Boolean> cm) {
		   link = cm; //va fatta la deep copy
	 }
	
	public void loadConnection (HashMap<Integer,List<Integer>> success,HashMap<Integer,List<Integer>> failed) {
		   success_ca = success;
		   fail_ca = failed;
	}
	
	public void color_ca (Color c) {
		 color_ca = c;
	}
	
	private void drawLink(Graphics g) {
		   Graphics2D g2 = (Graphics2D)g;
		   double x;
		   double y;
		   double d = host.dim;
		   g2.setPaint(Color.BLACK);
		 //aggiungere un controllo se link � null
		   for (int i = 0; i < n_host; i++) {
				for (int j = i + 1; j < n_host && j != i; j++) {
					if(link.get(i,j)) {
					   g2.draw( new Line2D.Double( (hosts.get(i).getX() + d/2),(hosts.get(i).getY() + d/2),
							   					   (hosts.get(j).getX() + d/2),(hosts.get(j).getY() + d/2)));
					}
				}
			}
	 }

	private void drawConnection(Graphics g, HashMap <Integer, List<Integer>> connection) {
		Graphics2D g2 = (Graphics2D) g;
		double x1;
		double x2;
		double y1;
		double y2;
		double d = host.dim;
		g2.setPaint(color_ca);
		for(int i = 0; i < n_host; i++) {
			int id = i + 1;  
			List<Integer> Ca = connection.get(id);
			if(Ca != null) {
				//carica le coordinate del host da cui parte la connessione
				x1 = hosts.get(i).getX();
				y1 = hosts.get(i).getY();
				ListIterator<Integer> il = Ca.listIterator();
				while(il.hasNext()) {
					//carica le coordinate del host a cui arriva la connessione
					int host_to = il.next();
					x2 = hosts.get(host_to - 1).getX();
					y2 = hosts.get(host_to - 1).getY();
					//disegna la linea
					g2.setStroke(new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER)); // g2 is an instance of Graphics2D
					g2.draw(new Line2D.Double(x1 + d/2,y1 + d/2,x2 + d/2,y2 + d/2));
				}
				    g2.setStroke(new BasicStroke(1)); //reimposta lo spessore della linea a 1
			}
		}
	}
	
	
   protected void paintComponent(Graphics g) {
	   super.paintComponent(g);
	   Graphics2D g2 = (Graphics2D)g;
	   
	   //abilit� antialiasing
	   g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
			   RenderingHints.VALUE_ANTIALIAS_ON);
	   
	 
	   g2.setPaint(Color.WHITE);
	   g2.fill(new Rectangle(0, 0,getWidth() - 1,getHeight() - 1));
	   
	   
	   if(link != null) {drawLink(g);};
	   color_ca(Color.GREEN);
	   if(success_ca != null) {color_ca(Color.GREEN);drawConnection(g,success_ca);}
	   color_ca(Color.RED);
	   if(fail_ca != null) {color_ca(Color.RED);drawConnection(g,fail_ca);}
	   
	   
	   
	   for (int i = 0; i < n_host; i++) {
		   hosts.get(i).paint(g2);
	   }
	   
	   g2.setPaint(Color.BLACK);
	   g2.draw(new Rectangle(0, 0,getWidth()-1,getHeight()-1));
   }

 
	    
}

