package main.java.terminal;


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
import main.proto.Protos.ResponseImporterDropwizard;
import main.proto.Protos.ImporterDropwizard;
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
	private	ReadMessage rm;
	private SendMessage sm;
	private Socket cs;

	public Leitor(Sistema system, Socket sock){
		this.sys = system;
		this.cs  = sock;
		this.rm = new ReadMessage(this.cs);
		this.sm = new SendMessage(this.cs);

	}

	public void run(){
		boolean flag = true;

		try{
			while(flag){
				System.out.println("Vou receber coisas " + this.sys + "\n");
				byte[] syn = this.rm.receiveMessage();
				NegSyn negsyn = NegSyn.parseFrom(syn);
				System.out.println("Recebi o Syn " + negsyn.getType());
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
				System.out.println("Entrei no FAB_PROD com " + pn);
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
			else if(negsyn.getType().equals(NegSyn.OpType.FAB_OVER)){
				Notification notification = Notification.parseFrom(cont);
				System.out.println("Entrei no FAB_OVER com " + notification);
				ConfirmNegotiations cn = sys.getAceptedOffers(notification.getFabricante(), notification.getProduto());
				byte[] bytes = cn.toByteArray();
				this.sm.sendServer(bytes);
				System.out.println(cn);
			}
			//OfertaImp -> BusinessConfirmation
			else if(negsyn.getType().equals(NegSyn.OpType.IMP_OFFER)){
				OfertaNegociador neg = OfertaNegociador.parseFrom(cont);
				System.out.println("Entrei no IMP_OFFER com " + neg);
				boolean res = sys.addOffer(neg);
				BusinessConfirmation bc = BusinessConfirmation.newBuilder().
																setResponse(res).
																setFabricante(neg.getProducer()).
																setProduto(neg.getProduct()).
																build();
				byte[] bytes = bc.toByteArray();
				this.sm.sendServer(bytes);
			}

			else if(negsyn.getType().equals(NegSyn.OpType.IMP_OVER)){
				Notification notification = Notification.parseFrom(cont);
				System.out.println("Entrei no IMP_OVER com " + notification);
				ConfirmNegotiations cn = sys.getPublishedOffers(notification.getFabricante(), notification.getProduto(), notification.getUsername());
				byte[] bytes = cn.toByteArray();
				this.sm.sendServer(bytes);
				System.out.println(cn);
			}
			//Depende do DROP a seguir
			else if(negsyn.getType().equals(NegSyn.OpType.DROP)){
				Dropwizard drop = Dropwizard.parseFrom(cont);
				handleDropwizard(drop);
			}
			else {
				System.out.println("O tipo da mensagem não corresponde com nenhuma condição");
			}

		}
		catch(Exception e){
			System.out.println(e.getMessage());
		}
	}

	public void handleDropwizard(Dropwizard drop){
		if(drop.getType().equals(Dropwizard.DropType.PROD)){
			ResponseProdutoDropwizard rpd = sys.getProdutosUser(drop.getUsername());
			byte[] bytes = rpd.toByteArray();
			this.sm.sendServer(bytes);
		}

		else if(drop.getType().equals(Dropwizard.DropType.NEG)){
			ResponseNegotiationDropwizard rpd = sys.getNegociosProdutoUser(drop.getUsername(), drop.getProd());
			byte[] bytes = rpd.toByteArray();
			this.sm.sendServer(bytes);
		}

		else if(drop.getType().equals(Dropwizard.DropType.IMP)){
			ResponseImporterDropwizard rpd = sys.getNegociosImportador(drop.getUsername());
			byte[] bytes = rpd.toByteArray();
			this.sm.sendServer(bytes);
		}
	}
}

class Sistema{

	private Map<String, Produtor> producers;
	private Map<String, List<Oferta>> importers;

	public Sistema(){
		this.producers = new HashMap<>();
		this.importers = new HashMap<>();
	}

	public boolean addProduct(ProdutoNegociador product){
		if(!this.producers.containsKey(product.getUsername())){
			System.out.println("O utilizador vai ser criado");
			this.producers.put(product.getUsername(), new Produtor(product.getUsername()));
		}
		System.out.println("O utilizador existe");
		String producer = product.getUsername();
		String product_name = product.getProduct().getName();
		boolean flag = containsProduct(producer, product_name);
		System.out.println("O produto " + product_name + " existe: " + flag);
		if(!flag){
			Map<String, Produto> products = producers.get(producer).getProducts();
			Produto p = new Produto(product.getUsername(), product.getProduct().getName(), product.getProduct().getMin(), product.getProduct().getMax(),
						product.getProduct().getPrice(), -1, product.getProduct().getDate());
			products.put(product_name, p);
			return true;
		}
		return false;
	}

	public boolean addOffer(OfertaNegociador offer){
		String producer = offer.getProducer();
		String product  = offer.getProduct();
		boolean flag = containsProduct(producer, product);
		System.out.println("O produto " + product + " existe: " + flag);
		if(flag){
			Produto prod = this.producers.get(producer).getProducts().get(product);
			if(prod.getMax() >= offer.getOffer().getQuantity() && prod.getPrice() <= offer.getOffer().getPrice() && 
				prod.getDate().compareTo(offer.getOffer().getDate()) > 0){
				System.out.println("O negocio vai ser adicionado");
				Oferta oferta = generateOffer(offer);
				sortOffers(prod, oferta);
				return true;
			}
			System.out.println("O produto " + product + " não foi adicionado porque " + (prod.getMax() >= offer.getOffer().getQuantity()) + 
				(prod.getPrice() <= offer.getOffer().getPrice()) + (prod.getDate().compareTo(offer.getOffer().getDate()) > 0));
		}
		return false;
	}

	public Oferta generateOffer(OfertaNegociador offer){
		String producer = offer.getProducer();
		String importer = offer.getOffer().getImportador();
		String product = offer.getProduct();
		String date = offer.getOffer().getDate();
		int quantity = offer.getOffer().getQuantity();
		int price = offer.getOffer().getPrice();
		int state = offer.getOffer().getState();
		return new Oferta(producer, importer, product, quantity, price, date, state);
	}

	public void sortOffers(Produto prod, Oferta offer){
		List<Oferta> ofertas = prod.getOffersList();
		int i = 0;
		for(; i < ofertas.size(); i++){
			Oferta of = ofertas.get(i);
			if(of.getPrice() < offer.getPrice()){
				ofertas.add(i, offer);
				this.importers.get(of.getImportador()).add(offer);
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
		System.out.println("Vou ver as ofertas que foram aceites");
		if(prod.getState() == -1){
			System.out.println("Vou mudar o estado dos produtos");
			List<Oferta> ofertas = prod.getOffersList();
			if(!prod.canProduce()){
				System.out.println("Não existem ofertas suficientes");
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
		System.out.println("O numero de pedidos aceites foram " + accepted.size());
		ConfirmNegotiations cn = ConfirmNegotiations.newBuilder().
												addAllAcepted(an).
												build();
		return cn;
	}

	public ConfirmNegotiations getPublishedOffers(String producer, String product_name, String importador){
		Produto prod = this.producers.get(producer).getProducts().get(product_name);
		if(prod.getState() == -1){
			System.out.println("Vou mudar o estado dos produtos");
			List<Oferta> ofertas = prod.getOffersList();
			if(!prod.canProduce()){
				System.out.println("Não existem ofertas suficientes");
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
		System.out.println("O numero de pedidos aceites foram " + accepted.size());
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

	public ResponseImporterDropwizard getNegociosImportador(String username){
		if(!this.importers.containsKey(username)){
			List<ImporterDropwizard> res = new ArrayList<>();
			return ResponseImporterDropwizard.newBuilder()
											 .addAllImporter(res)
											 .build();
		}
		ResponseImporterDropwizard.Builder rid = ResponseImporterDropwizard.newBuilder();
		List<ImporterDropwizard> res = new ArrayList<>();
		for(Oferta of: this.importers.get(username)){
			ImporterDropwizard importer = ImporterDropwizard.newBuilder()
															.setFabricante(of.getProducer())
															.setProductName(of.getImportador())
															.setPrice(of.getPrice())
															.setAmount(of.getQuantity())
															.setData(of.getDate())
															.setState(of.getState())
															.build();
			res.add(importer);
		}
		return rid.addAllImporter(res).build();
	}

	public String toString(){
		String s = "\n";
		for(String str: this.producers.keySet()){
			s = s + str + "		Tamanho: " + this.producers.get(str).getProducts().keySet().size() +"\n";
			for(Produto prod: this.producers.get(str).getProducts().values()){
				s = s + prod.toString() + "\n";
			}
		}
		return s;
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

	public String toString(){
		return "	Nome: " + this.name + " Producer: " + this.producer + " estado: " + this.state;
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
			else{
				value = value - of.getQuantity();
				of.setState(1);
			}
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
