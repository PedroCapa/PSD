import com.google.protobuf.MapField;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.net.Socket;
import java.net.ServerSocket;
import java.io.IOException;

import main.proto.Protos.ResponseProdutoDropwizard;
import main.proto.Protos.Production;
import main.proto.Protos.ResponseNegotiationDropwizard;
import main.proto.Protos.NegotiationDropwizard;
import main.proto.Protos.NegSyn;
import main.proto.Protos.ConfirmNegotiations;
import main.proto.Protos.AceptedNegotiation;
import main.proto.Protos.Notification;
import main.proto.Protos.Negotiation;
import main.proto.Protos.ProdutoNegociador;
import main.proto.Protos.OfertaImp;
import main.proto.Protos.OfertaNegociador;
import main.proto.Protos.BusinessConfirmation;
import main.proto.Protos.Dropwizard;

import main.java.terminal.ReadMessage;
import main.java.terminal.SendMessage;

public class Negociador{

	public static void main(String[] args) {
		int port = Integer.parseInt(args[0]);

		try{
			ServerSocket ss = new ServerSocket(port);
			Sistema system = new Sistema();
		
			while(true){
				try{
					Socket cs = ss.accept();
					Leitor lc = new Leitor(system,cs);
					Thread t = new Thread(lc);
					t.start();
				}catch(IOException e){
					System.out.println(e.getMessage());
				}
			}
		}catch(IOException e){
			System.out.println(e.getMessage());
		}

	}
}

class Leitor implements Runnable{
	private Sistema sys;
	private	ReadMessage rm = new ReadMessage(this.cs);
	private SendMessage sm = new SendMessage(this.cs);
	private Socket cs;

	public Leitor(Sistema system, Socket sock){
		this.sys = system;
		this.cs  = sock;
	}

	public void run(){
		boolean flag = true;

		try{
			while(flag){
				byte[] syn = this.rm.receiveMessage();
				NegSyn negsyn = NegSyn.parseFrom(syn);

				receiveCont(negsyn);
			}
		}
		catch(Exception e){
			System.out.println(e.getMessage());
		}
	}

	public void receiveCont(NegSyn negsyn){
		try{

			byte[] cont = this.rm.receiveMessage();
			//ProdutoNegociador -> BusinessConfirmation
			if(negsyn.getType().equals(NegSyn.OpType.FAB_PROD)){
				ProdutoNegociador pn = ProdutoNegociador.parseFrom(cont);
				boolean res = sys.addProduct(pn);
				BusinessConfirmation bc = BusinessConfirmation.newBuilder().
																setResponse(res).
																setFabricante(pn.getUsername()).
																setProduto(pn.getProduct().getName()).
																build();
				byte[] bytes = bc.toByteArray();
				this.sm.sendServer(bytes);
			}
			//Notification -> ConfirmNegotiations
			if(negsyn.getType().equals(NegSyn.OpType.FAB_OVER)){
				Notification notification = Notification.parseFrom(cont);
				ConfirmNegotiations cn = sys.getAceptedOffers(notification.getFabricante(), notification.getProduto());
				byte[] bytes = cn.toByteArray();
				this.sm.sendServer(bytes);
			}
			//OfertaImp -> BusinessConfirmation
			if(negsyn.getType().equals(NegSyn.OpType.IMP_OFFER)){
				OfertaNegociador neg = OfertaNegociador.parseFrom(cont);
				Oferta oferta = new Oferta(neg.getProducer(), neg.getOffer().getImportador(), neg.getProduct(), neg.getOffer().getQuantity(), 
									neg.getOffer().getPrice(),neg.getOffer().getDate(), neg.getOffer().getState());
				boolean res = sys.addOffer(oferta);
				BusinessConfirmation bc = BusinessConfirmation.newBuilder().
																setResponse(res).
																setFabricante(neg.getProducer()).
																setProduto(neg.getProduct()).
																build();
				byte[] bytes = bc.toByteArray();
				this.sm.sendServer(bytes);
			}

			if(negsyn.getType().equals(NegSyn.OpType.IMP_OVER)){
				Notification notification = Notification.parseFrom(cont);
				ConfirmNegotiations cn = sys.getPublishedOffers(notification.getFabricante(), notification.getProduto(), notification.getUsername());
				byte[] bytes = cn.toByteArray();
				this.sm.sendServer(bytes);
			}
			//Depende do DROP a seguir
			if(negsyn.getType().equals(NegSyn.OpType.DROP)){
				Dropwizard drop = Dropwizard.parseFrom(cont);
				handleDropwizard(drop);
			}

		}
		catch(Exception e){
			System.out.println(e.getMessage());
		}
	}

	public void handleDropwizard(Dropwizard drop){
		if(drop.getType().equals(Dropwizard.DropType.PROD)){
			ResponseProdutoDropwizard rpd = sys.getProdutosUser(drop.getUsername());
		}

		if(drop.getType().equals(Dropwizard.DropType.NEG)){

		}

		if(drop.getType().equals(Dropwizard.DropType.IMP)){
			ResponseNegotiationDropwizard rpd = sys.getNegociosProdutoUser(drop.getUsername(), drop.getProd());
		}


	}
}

class Sistema{

	private Map<String, Produtor> producers;

	public Sistema(){
		this.producers = new HashMap<>();
	}

	public boolean addProduct(ProdutoNegociador product){
		if(!this.producers.containsKey(product.getUsername())){
			this.producers.put(product.getUsername(), new Produtor(product.getUsername()));
		}
		String producer = product.getUsername();
		String product_name = product.getProduct().getName();
		boolean flag = containsProduct(producer, product_name);
		if(!flag){
			Map<String, Produto> products = producers.get(producer).getProducts();
			Produto p = new Produto(product.getUsername(), product.getProduct().getName(), product.getProduct().getMin(), product.getProduct().getMax(),
						product.getProduct().getPrice(), -1, product.getProduct().getDate());
			products.put(product_name, p);
		}
		return false;
	}

	public boolean addOffer(Oferta offer){
		String producer = offer.getProducer();
		String product  = offer.getProduct();
		boolean flag = containsProduct(producer, product);
		if(flag){
			Produto prod = this.producers.get(producer).getProducts().get(product);
			if(prod.getMax() >= offer.getQuantity() && prod.getPrice() <= offer.getPrice() && prod.getDate().compareTo(offer.getDate()) > 0){
				sortOffers(prod, offer);
				return true;
			}
		}
		return false;
	}

	public void sortOffers(Produto prod, Oferta offer){
		List<Oferta> ofertas = prod.getOffersList();
		int i = 0;
		for(; i < ofertas.size(); i++){
			Oferta of = ofertas.get(i);
			if(of.getPrice() < offer.getPrice()){
				ofertas.add(i, offer);
				break;
			}
		}
		if(i == ofertas.size()){
			ofertas.add(i, offer);
		}
	}

	public boolean containsProduct(String producer, String product){
		if(this.producers.containsKey(producer)){
			Map<String, Produto> products = this.producers.get(producer).getProducts();
			if(products.containsKey(product)){
				return true;
			}
			return false;
		}
		return false;
	}

	public ConfirmNegotiations getAceptedOffers(String producer, String product_name){
		Produto prod = this.producers.get(producer).getProducts().get(product_name);
		if(prod.getState() == -1){
			List<Oferta> ofertas = prod.getOffersList();
			if(!prod.canProduce()){
				prod.setState(0);
				prod.setOffers();
			}
			else
				prod.changeStatus();
		}
		List<Oferta> ofertas = prod.getOffersList();
		List<Oferta> accepted = new ArrayList<>();
		for(Oferta of: ofertas){
			if(of.getState() == 1){
				accepted.add(of);
			}
		}
		List<AceptedNegotiation> an = new ArrayList<>();
		for(Oferta of: accepted){
			AceptedNegotiation acn = AceptedNegotiation.newBuilder().
												setImporterOffer(of.getImportador()).
												setProductName(of.getProducer()).
												setPrice(of.getPrice()).
												setAmount(of.getQuantity()).
												setData(of.getDate()).
												setState(of.getState()).
												build();
			an.add(acn);
		}
		ConfirmNegotiations cn = ConfirmNegotiations.newBuilder().
												addAllAcepted(an).
												build();
		return cn;
	}

	public ConfirmNegotiations getPublishedOffers(String producer, String product_name, String importador){
		Produto prod = this.producers.get(producer).getProducts().get(product_name);
		if(prod.getState() == -1){
			List<Oferta> ofertas = prod.getOffersList();
			if(!prod.canProduce()){
				prod.setState(0);
				prod.setOffers();
			}
			else
				prod.changeStatus();
		}
		List<Oferta> ofertas = prod.getOffersList();
		List<Oferta> accepted = new ArrayList<>();
		for(Oferta of: ofertas){
			if(of.getState() == 1 && of.getImportador().equals(importador)){
				accepted.add(of);
			}
		}
		List<AceptedNegotiation> an = new ArrayList<>();
		for(Oferta of: accepted){
			AceptedNegotiation acn = AceptedNegotiation.newBuilder().
												setImporterOffer(of.getImportador()).
												setProductName(of.getProducer()).
												setPrice(of.getPrice()).
												setAmount(of.getQuantity()).
												setData(of.getDate()).
												setState(of.getState()).
												build();
			an.add(acn);
		}
		ConfirmNegotiations cn = ConfirmNegotiations.newBuilder().
												addAllAcepted(an).
												build();
		return cn;
	}

	public ResponseProdutoDropwizard getProdutosUser(String username){
		if(!this.producers.containsKey(username)){
			return ResponseProdutoDropwizard.newBuilder().
				   addAllProducts(new ArrayList<>()).
				   build();
		}

		List<Produto> produtos = new ArrayList<>(this.producers.get(username).getProducts().values());
		List<Production> market = new ArrayList<>();
		for(Produto p: produtos){
			Production production = Production.newBuilder().
												setProductName(p.getName()).
												setMin(p.getMin()).
												setMax(p.getMax()).
												setPrice(p.getPrice()).
												setData(p.getDate()).
												build();
			market.add(production);
		}
		ResponseProdutoDropwizard rpd = ResponseProdutoDropwizard.newBuilder().
												addAllProducts(market).
												build();

		return rpd;
	}

	public ResponseNegotiationDropwizard getNegociosProdutoUser(String username, String product_name){
		if(!this.producers.containsKey(username) || !!this.producers.get(product_name).getProducts().containsKey(product_name)){
			return ResponseNegotiationDropwizard.newBuilder().
				   addAllNegotiation(new ArrayList<>()).
				   build();
		}

		List<Oferta> ofertas = new ArrayList<>(this.producers.get(username).getProducts().get(product_name).getOffersList());
		List<NegotiationDropwizard> market = new ArrayList<>();
		for(Oferta of: ofertas){
			NegotiationDropwizard production = NegotiationDropwizard.newBuilder().
												setUsername(of.getImportador()).
												setPrice(of.getPrice()).
												setAmount(of.getQuantity()).
												setData(of.getDate()).
												setState(of.getState()).
												build();
			market.add(production);
		}
		ResponseNegotiationDropwizard rpd = ResponseNegotiationDropwizard.newBuilder().
												addAllNegotiation(market).
												build();

		return rpd;
	}
}


class Oferta{
	private String producer;
	private String importador;
	private String product;
	private int quantity;
	private int price;
	private String date;
	private int state;

	public Oferta(String producer, String importador, String prodduct, int quantity, int price, String date, int state){
		this.producer = producer;
		this.importador = importador;
		this.product = product;
		this.quantity = quantity;
		this.price = price;
		this.date = date;
		this.state = state;
	}

	public String getProducer(){
		return this.producer;
	}

	public String getImportador(){
		return this.importador;
	}

	public String getProduct(){
		return this.product;
	}

	public int getQuantity(){
		return this.quantity;
	}

	public int getPrice(){
		return this.price;
	}

	public int getState(){
		return this.state;
	}

	public String getDate(){
		return this.date;
	}

	public void setState(int i){
		this.state = i;
	}
}


class Produto{
	private String name;
	private String producer;
	private int min;
	private int max;
	private int price;
	private int state;
	private String date;
	List<Oferta> offers;

	public Produto(String name, String producer, int min, int max, int price, int state, String date){
		this.name = name;
		this.producer = producer;
		this.min = min;
		this.max = max;
		this.price = price;
		this.state = state;
		this.date = date;
		this.offers = new ArrayList<>();
	}

	public String getName(){
		return this.name;
	}	

	public String getProducer(){
		return this.producer;
	}

	public int getMin(){
		return this.min;
	}

	public int getMax(){
		return this.max;
	}

	public int getPrice(){
		return this.price;
	}

	public int getState(){
		return this.state;
	}
	
	public String getDate(){
		return this.date;
	}
	
	public List<Oferta> getOffersList(){
		return this.offers;		
	}

	public void setState(int i){
		this.state = i;
	}

	public void setOffers(){
		for(Oferta of: this.offers){
			of.setState(0);
		}
	}

	public boolean canProduce(){
		for (Oferta of: this.offers) {
			this.min = this.min - of.getQuantity();
		}
		if(min <= 0)
			return true;
		else
			return false;
	}

	public void changeStatus(){
		int value = this.max;
		for(Oferta of: this.offers){
			if (value - of.getQuantity() < 0)
				of.setState(0);
			else
				of.setState(1);
		}
	}
}

class Produtor{
	private Map<String, Produto> products = new HashMap<>();
	private String username;

	public String getUsername(){
		return this.username;
	}

	public Produtor(String username){
		this.username = username;
		this.products = new HashMap<>();
	}

	public Map<String, Produto> getProducts(){
		return this.products;
	}

	public Produto getProduto(String product_name){
		return this.products.get(product_name);
	}
}
